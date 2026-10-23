{{- define "nextcloud.wait.nextcloud" -}}
{{- $fullname := (include "tc.v1.common.lib.chart.names.fullname" $) -}}
{{- $ncURL := printf "%v-nextcloud:%v" $fullname .Values.service.nextcloud.ports.nextcloud.targetPort }}
enabled: true
type: init
imageSelector: image
resources:
  excludeExtra: true
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 10m
    memory: 50Mi
securityContext:
command: /bin/sh
args:
  - -c
  - |
    echo "Waiting Nextcloud [{{ $ncURL }}] to be ready and installed..."
    until \
          bash -c "exec 3<>/dev/tcp/$(echo {{ $ncURL }} | cut -d: -f1)/$(echo {{ $ncURL }} | cut -d: -f2)" 2>/dev/null;
    do
      echo "Waiting Nextcloud [{{ $ncURL }}] to be ready and installed..."
      sleep 3
    done

    echo "Nextcloud is ready and installed..."
    echo "Starting Nginx..."
{{- end -}}
