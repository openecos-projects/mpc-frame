#include "VFrameTop.h"
#include "verilated.h"

#if VM_TRACE
#include "verilated_fst_c.h"
#endif

#include <algorithm>
#include <cstdint>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <memory>
#include <string>
#include <vector>

namespace {
std::vector<std::uint8_t> flash_image;
std::vector<std::uint64_t> gpio_expect_values;
std::string uart_stop_text;
std::string uart_fail_text;
std::string uart_seen_text;
std::uint64_t gpio_expect_mask = 0xf;
std::size_t gpio_expect_index = 0;
bool gpio_expect_matched = false;
bool uart_stop_matched = false;
bool uart_fail_matched = false;

std::string plusarg_value(const char* prefix, int argc, char** argv) {
  const std::string key(prefix);
  for (int index = 1; index < argc; ++index) {
    const std::string arg(argv[index]);
    if (arg.rfind(key, 0) == 0) {
      return arg.substr(key.size());
    }
  }
  return {};
}

std::uint64_t plusarg_u64(const char* prefix, std::uint64_t fallback,
                          int argc, char** argv) {
  const std::string value = plusarg_value(prefix, argc, argv);
  if (value.empty()) {
    return fallback;
  }
  char* end = nullptr;
  const auto parsed = std::strtoull(value.c_str(), &end, 0);
  if (end == value.c_str() || *end != '\0') {
    std::cerr << "Invalid integer plusarg " << prefix << value << '\n';
    std::exit(2);
  }
  return parsed;
}

std::vector<std::uint64_t> plusarg_u64_list(const char* prefix,
                                             int argc, char** argv) {
  const std::string value = plusarg_value(prefix, argc, argv);
  std::vector<std::uint64_t> result;
  std::size_t start = 0;
  while (!value.empty() && start <= value.size()) {
    const auto end = value.find(',', start);
    const auto token = value.substr(start, end - start);
    char* parse_end = nullptr;
    const auto parsed = std::strtoull(token.c_str(), &parse_end, 0);
    if (parse_end == token.c_str() || *parse_end != '\0') {
      std::cerr << "Invalid integer list plusarg " << prefix << value << '\n';
      std::exit(2);
    }
    result.push_back(parsed);
    if (end == std::string::npos) {
      break;
    }
    start = end + 1;
  }
  return result;
}

class UartRxDriver {
 public:
  UartRxDriver(std::string input, std::uint64_t start_cycle)
      : input_(std::move(input)), start_cycle_(start_cycle) {}

  int level(std::uint64_t cycle) const {
    constexpr std::uint64_t kBitCycles = 13 * 16;
    if (input_.empty() || cycle < start_cycle_) {
      return 1;
    }
    const auto bit_index = (cycle - start_cycle_) / kBitCycles;
    const auto frame = bit_index / 10;
    const auto bit = bit_index % 10;
    if (frame >= input_.size() || bit == 9) {
      return 1;
    }
    if (bit == 0) {
      return 0;
    }
    return (static_cast<std::uint8_t>(input_[frame]) >> (bit - 1)) & 1U;
  }

 private:
  std::string input_;
  std::uint64_t start_cycle_;
};

bool load_flash_image(const std::string& path) {
  std::ifstream file(path, std::ios::binary);
  if (!file) {
    return false;
  }
  flash_image.assign(std::istreambuf_iterator<char>(file),
                     std::istreambuf_iterator<char>());
  return true;
}

void set_frame_bit(VFrameTop* top, std::uint32_t bit, bool value) {
  const std::uint32_t word = bit / 32;
  const std::uint32_t mask = 1U << (bit % 32);
  if (value) {
    top->user_io[word] |= mask;
  } else {
    top->user_io[word] &= ~mask;
  }
}

void drive_inputs(VFrameTop* top, int uart_rx, std::uint64_t gpio_in,
                  std::uint64_t gpio_drive) {
  for (std::uint32_t bit = 0; bit < 7; ++bit) {
    set_frame_bit(top, bit, false);
  }
  set_frame_bit(top, 7, uart_rx != 0);
  for (std::uint32_t gpio_bit = 0; gpio_bit < 54; ++gpio_bit) {
    if (((gpio_drive >> gpio_bit) & 1ULL) != 0) {
      set_frame_bit(top, 19 + gpio_bit, ((gpio_in >> gpio_bit) & 1ULL) != 0);
    }
  }
}

std::uint64_t sample_gpio(const VFrameTop* top) {
  std::uint64_t value = 0;
  for (std::uint32_t gpio_bit = 0; gpio_bit < 54; ++gpio_bit) {
    const std::uint32_t frame_bit = 19 + gpio_bit;
    value |= static_cast<std::uint64_t>(
                 (top->user_io[frame_bit / 32] >> (frame_bit % 32)) & 1U)
             << gpio_bit;
  }
  return value;
}

void record_gpio(std::uint64_t value) {
  if (gpio_expect_values.empty() || gpio_expect_matched) {
    return;
  }
  if ((value & gpio_expect_mask) !=
      (gpio_expect_values[gpio_expect_index] & gpio_expect_mask)) {
    return;
  }
  gpio_expect_matched = ++gpio_expect_index >= gpio_expect_values.size();
}

void record_uart(std::uint8_t byte) {
  uart_seen_text.push_back(static_cast<char>(byte));
  const auto keep = std::max(uart_stop_text.size(), uart_fail_text.size());
  if (uart_seen_text.size() > keep) {
    uart_seen_text.erase(0, uart_seen_text.size() - keep);
  }
  if (!uart_stop_text.empty() && uart_seen_text.size() >= uart_stop_text.size()) {
    uart_stop_matched = uart_seen_text.compare(
        uart_seen_text.size() - uart_stop_text.size(), uart_stop_text.size(),
        uart_stop_text) == 0;
  }
  if (!uart_fail_text.empty() && uart_seen_text.size() >= uart_fail_text.size()) {
    uart_fail_matched = uart_seen_text.compare(
        uart_seen_text.size() - uart_fail_text.size(), uart_fail_text.size(),
        uart_fail_text) == 0;
  }
}

bool all_conditions_matched() {
  if (uart_stop_text.empty() && gpio_expect_values.empty()) {
    return false;
  }
  return (uart_stop_text.empty() || uart_stop_matched) &&
         (gpio_expect_values.empty() || gpio_expect_matched);
}
}  // namespace

extern "C" void flash_read(int addr, int* data) {
  std::uint32_t word = 0;
  if (addr >= 0) {
    const auto base = static_cast<std::size_t>(addr);
    for (std::size_t byte = 0; byte < 4; ++byte) {
      if (base + byte < flash_image.size()) {
        word |= static_cast<std::uint32_t>(flash_image[base + byte]) << (8 * byte);
      }
    }
  }
  *data = static_cast<int>(word);
}

extern "C" void uart_tx_byte(int data) {
  record_uart(static_cast<std::uint8_t>(data));
}

extern "C" void debug(int, int) {}

extern "C" void ebreak(int) {
  Verilated::gotFinish(true);
}

int main(int argc, char** argv) {
  std::cout << std::unitbuf;
  auto context = std::make_unique<VerilatedContext>();
  context->commandArgs(argc, argv);

  const auto bootrom = plusarg_value("+bootrom=", argc, argv);
  const auto wave = plusarg_value("+wave=", argc, argv);
  const auto uart_input = plusarg_value("+uart-in=", argc, argv);
  uart_stop_text = plusarg_value("+uart-stop-text=", argc, argv);
  uart_fail_text = plusarg_value("+uart-fail-text=", argc, argv);
  const auto max_cycles = plusarg_u64("+max-cycles=", 200000, argc, argv);
  const auto uart_start = plusarg_u64("+uart-start-cycle=", 10000, argc, argv);
  const auto gpio_in = plusarg_u64("+gpio-in=", 0, argc, argv);
  const auto gpio_drive = plusarg_u64("+gpio-drive=", 0, argc, argv);
  gpio_expect_mask = plusarg_u64("+gpio-expect-mask=", 0xf, argc, argv);
  gpio_expect_values = plusarg_u64_list("+gpio-expect=", argc, argv);

  if (!load_flash_image(bootrom)) {
    std::cerr << "Boot ROM image not found: " << bootrom << '\n';
    return 2;
  }
  std::cout << "Boot ROM image: " << bootrom << " (" << flash_image.size()
            << " bytes)\nMax cycles: " << max_cycles << '\n';

  auto top = std::make_unique<VFrameTop>(context.get());
  UartRxDriver uart_rx(uart_input, uart_start);

#if VM_TRACE
  std::unique_ptr<VerilatedFstC> trace;
  if (!wave.empty()) {
    context->traceEverOn(true);
    trace = std::make_unique<VerilatedFstC>();
    top->trace(trace.get(), 99);
    trace->open(wave.c_str());
  }
#endif

  top->reset = 1;
  for (std::uint64_t cycle = 0;
       cycle < max_cycles && !context->gotFinish() && !all_conditions_matched() &&
       !uart_fail_matched;
       ++cycle) {
    drive_inputs(top.get(), uart_rx.level(cycle), gpio_in, gpio_drive);
    top->clock = 0;
    top->eval();
    record_gpio(sample_gpio(top.get()));
#if VM_TRACE
    if (trace) trace->dump(context->time());
#endif
    context->timeInc(1);

    top->reset = cycle < 20;
    drive_inputs(top.get(), uart_rx.level(cycle), gpio_in, gpio_drive);
    top->clock = 1;
    top->eval();
    record_gpio(sample_gpio(top.get()));
#if VM_TRACE
    if (trace) trace->dump(context->time());
#endif
    context->timeInc(1);
  }

  top->final();
#if VM_TRACE
  if (trace) trace->close();
#endif

  if (uart_fail_matched || (!uart_stop_text.empty() && !uart_stop_matched) ||
      (!gpio_expect_values.empty() && !gpio_expect_matched)) {
    std::cerr << "SIM FAIL: acceptance condition not met at " << context->time()
              << " ticks\n";
    return 1;
  }
  std::cout << "SIM PASS: acceptance conditions observed at " << context->time()
            << " ticks\n";
  return 0;
}
