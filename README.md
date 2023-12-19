# Nginx OpenTelemetry (OTEL) module

The Nginx OTEL module package, designed for Debian/Ubuntu-based systems, 
is exclusively available to Nginx Plus users through official distribution and maintenance by Nginx. 
While Nginx provides all the open-source code, they recommend users compile and distribute the module independently.

This particular module is derived from the Open Telemetry Nginx addon 
(found at [https://github.com/open-telemetry/opentelemetry-cpp-contrib/tree/main/instrumentation/nginx](https://github.com/open-telemetry/opentelemetry-cpp-contrib/tree/main/instrumentation/nginx)), 
not the Nginx-based source ([https://github.com/nginxinc/nginx-otel](https://github.com/nginxinc/nginx-otel)). 
Both utilize `opentelemetry-cpp`, resulting in nearly identical functionality. 
However, the Open Telemetry addon is configured externally rather than directly within Nginx using the `nginx.conf` file.

Notably, comprehensive tutorials for compiling this module for Alpine-based systems or ARM CPUs are scarce. 
Therefore, this repository provides examples for building and configuring the Nginx OTEL module for Alpine.

> **Warning**
> It's crucial to compile the module using the same Nginx source code version as the one in operation.

The compilation process yields a module file, `otel_ngx_module.so`, located in the `/usr/lib/nginx/modules/` directory. 
While this file can be simply archived for distribution, a repeatable process is advised. 
This means establishing a build pipeline, especially when the Nginx version used for the build becomes outdated.

### Building module

```bash
docker build \
    -f Dockerfile \
    --build-arg=IMAGE=nginx:1.21.6-alpine .
```

### Usage of module

```dockerfile
# Version must be same for source image and for version that was used for build module
FROM nginx:1.25.3-alpine

RUN apk add --no-cache tar libstdc++

# Change Nginx version and/or architecture (amd64 / arm64)
ADD https://github.com/contember/nginx-open-telemetry-module/releases/download/v1.0.0/otel_ngx_module_1.25.3-alpine_amd64.tgz /opt

# Unzip asset and put it into rigt place
RUN cd /opt ; tar xf otel_ngx_module_1.25.3-alpine_amd64.tgz
RUN cp /opt/otel_ngx_module.so /usr/lib/nginx/modules/otel_ngx_module.so

# (Optional) put custom configuration files
COPY opentelemetry.toml /etc/nginx/opentelemetry.toml
COPY nginx.conf /etc/nginx/nginx.conf
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
    opentelemetry_config /etc/nginx/opentelemetry.toml;
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

### Related sources
- [Open Telemetry C++ sdk](https://github.com/open-telemetry/opentelemetry-cpp)
- [Open Telemetry Nginx module](https://github.com/open-telemetry/opentelemetry-cpp-contrib)
- [Nginx Open Telemetry module](https://github.com/nginxinc/nginx-otel)
- [Inspiration for this repository](https://github.com/tangx/Nginx-With-OpenTelemetry)
