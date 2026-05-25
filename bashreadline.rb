require 'rbbcc'

$stdout.sync = true

# pid lives in the upper 32 bits
PID_TGID_SHIFT = 32

# max bytes to read from readline
MAX_LINE_LEN = 256

# c code injected into the kernel
BPF_CODE = <<~C
  #include <uapi/linux/ptrace.h>

  #define MAX_LINE_LEN   #{MAX_LINE_LEN}
  #define PID_TGID_SHIFT #{PID_TGID_SHIFT}

  // struct passed to user space via ring buffer
  struct data_t {
      u32  pid;
      char line[MAX_LINE_LEN];
  };

  BPF_PERF_OUTPUT(events);

  // fires when readline returns the typed string
  int capture_readline(struct pt_regs *ctx) {
      struct data_t data = {};

      data.pid = bpf_get_current_pid_tgid() >> PID_TGID_SHIFT;

      // grabs pointer to the user string from the register
      const char *line = (const char *)PT_REGS_RC(ctx);
      
      // safely read from user space memory
      bpf_probe_read_user_str(data.line, MAX_LINE_LEN, line);

      // push to perf ring buffer
      events.perf_submit(ctx, &data, sizeof(data));
      return 0;
  }
C

b = RbBCC::BCC.new(text: BPF_CODE)

# attach hook directly to bash binary
b.attach_uretprobe(name: "/bin/bash", sym: "readline", fn_name: "capture_readline")

puts "capturing bash input system-wide (ctrl+c to exit)\n\n"
printf "%-8s  %s\n", "PID", "COMMAND"
puts "─" * 40

# unpack raw bytes: u32 + char array
b["events"].open_perf_buffer do |_cpu, data, size|
  pid, line = data.to_str(size).unpack("La#{MAX_LINE_LEN}")
  printf "%-8d  %s\n", pid, line.delete("\x00")
end

begin
  loop { b.perf_buffer_poll }
rescue Interrupt
  puts "\nexiting"
end