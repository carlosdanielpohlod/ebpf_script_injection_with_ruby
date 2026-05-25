# ebpf + ruby

hooks into bash's readline() and prints everything typed, system-wide.

## build

```bash
docker build -t ruby-ebpf-tracer .
```

## run

```bash
docker run --rm -it \
  --privileged \
  -v /lib/modules:/lib/modules:ro \
  -v /usr/src:/usr/src:ro \
  -v /bin/bash:/bin/bash:ro \
  ruby-ebpf-tracer ruby bashreadline.rb
```

open another terminal and type stuff.
