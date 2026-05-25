# hooks into readline function to sniff bash inputs system wide
# requires docker and root mode
set -euo pipefail

IMAGE=ruby-ebpf-tracer

exec docker run --rm -it \
  --privileged \
  `# BCC needs host's kernel modules to load the BPF program` \
  -v /lib/modules:/lib/modules:ro \
  `# Headers so BCC can compile the C code on the fly` \
  -v /usr/src:/usr/src:ro \
  `# Expose host's bash binary so BCC can find the exact readline offset` \
  -v /bin/bash:/bin/bash:ro \
  "$IMAGE" ruby bashreadline.rb