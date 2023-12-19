# Nginx OpenTelemetry (OTEL) module

Currently, Nginx OTEL module package for Debian/Ubuntu based systems is officially distributed and maintained
by Nginx but its available only for Nginx Plus users. All source codes are open sources by Nginx, 
and suggesting to compile and distribute module by yourself.

This exact module comes from Open Telemetry Nginx addon (https://github.com/open-telemetry/opentelemetry-cpp-contrib/tree/main/instrumentation/nginx)
and not from Nginx based (https://github.com/nginxinc/nginx-otel) but both of them internally using `opentelemetry-cpp`
so functionality is almost identical expect Open Telemetry addon is configured externally and not directly with Nginx
dialect in `nginx.conf` like files.

But there is not much of fully describing tutorials how to compile for module compatible with Alpine base systems and/or AMR
based CPUs so this repository comes with examples how to build & configure Nginx OTEL module for Alpine.

> **Warning**
> Important to mention is that module must be compiled on same source code of Nginx as is used for running it

Output of building process is simply module file `otel_ngx_module.so` located in `/usr/lib/nginx/modules/` folder.
You can simply distribute this file by archiving it, but It's suggested to make process repeatable,
that means you need some form of building pipeline for example when Nginx version that is used for build will be outdated.


### Building module

```bash
docker build \
    -f Dockerfile \
    --build-arg=IMAGE=nginx:1.21.6-alpine .
```

### Usage of module

```dockerfile
FROM nginx:1.21.6-alpine

RUN apk add --no-cache unzip libstdc++

ADD https://github.com/contember/nginx-open-telemetery-module/releases/download/todo.tgz /opt

RUN cd /opt && unzip todo.tgz; tar xvfz todo.tgz
RUN cp /opt/otel_ngx_module.so /usr/lib/nginx/modules/otel_ngx_module.so
```

### Usage in examples

```nginx configuration
# Location for module copied from build pipeline
load_module /etc/nginx/modules/otel_ngx_module.so;

user  nginx;
worker_processes  auto;

error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    # Configuration for OpenTelemetry module
    opentelemetry_config /etc/nginx/opentelemetry_module.toml;
    access_log /var/log/nginx/access.log  main;

    keepalive_timeout  65;

    server {
        listen 127.0.0.1:80;

        location / {
            opentelemetry on;
            opentelemetry_propagate;

            add_header Content-Type text/plain;
            return 200 "Hello World!";
        }
    }

    include /etc/nginx/conf.d/*.conf;
}
```

#### Example of configuration
More details about possibility of configuration files can be [found here](https://github.com/open-telemetry/opentelemetry-cpp-contrib/tree/2a0db982f3d7ee91dfbe8150435e49e837bfb7ce/instrumentation/nginx#usage).
Or in example of file [permalink to example](https://github.com/open-telemetry/opentelemetry-cpp-contrib/blob/2a0db982f3d7ee91dfbe8150435e49e837bfb7ce/instrumentation/nginx/test/conf/otel-nginx.toml).

```tomp
exporter = "otlp"
processor = "batch"

[exporters.otlp]
host = "localhost"
port = 4317

[processors.batch]
max_queue_size = 2048
schedule_delay_millis = 5000
max_export_batch_size = 512

[service]
name = "nginx-ingress" # Opentelemetry resource name

[sampler]
name = "AlwaysOn" # Also: AlwaysOff, TraceIdRatioBased
ratio = 0.1
parent_based = false
```
