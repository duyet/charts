# hermes-agent

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v2026.6.5](https://img.shields.io/badge/AppVersion-v2026.6.5-informational?style=flat-square)

Hermes Agent by NousResearch — a self-hosted autonomous AI agent with an OpenAI-compatible gateway, web dashboard, persistent memory, and sandboxed tool execution.

**Homepage:** <https://hermes-agent.nousresearch.com>

Deploys [Hermes Agent](https://hermes-agent.nousresearch.com) (NousResearch) — a
self-hosted autonomous AI agent — using **basic Kubernetes resources only** (no
CRDs, no operator). A single stateful pod runs the OpenAI-compatible gateway and
the web dashboard, backed by **two separate persistent volumes**.

## Features

- **Two-volume persistence by design**
  - `data` → `/opt/data` (`HERMES_HOME`): core agent state — config, sessions,
    memories, skills, logs.
  - `workspace` → `/opt/workspace`: the agent's **working directory**
    (`terminal.cwd`) for git projects and data. Sized, backed up and recycled
    independently from core state.
- **Dashboard** (port `9119`) and **OpenAI-compatible API** (port `8642`) in one
  container — toggle each independently.
- **Secrets**: chart-managed Secret or `existingSecret` for LLM provider keys,
  API key, dashboard credentials, bot tokens.
- **Monitoring**: optional Prometheus `ServiceMonitor`.
- **Network isolation**: optional `NetworkPolicy` with default-deny ingress and
  DNS+HTTPS-only egress.
- **Seamless upgrades**: change `image.tag` and `helm upgrade` — `Recreate`
  strategy guarantees the old single-writer pod stops before the new one starts.
- **Safe defaults**: non-root (UID 10000), dropped capabilities, seccomp
  `RuntimeDefault`, config checksum auto-restart, fail-fast validation.

## Quick start

```console
# Add the repo
helm repo add duyet https://duyet.github.io/charts

# Minimal install (OpenRouter, no extras)
helm install hermes duyet/hermes-agent \
  --set secrets.data.API_SERVER_KEY="$(openssl rand -hex 16)" \
  --set secrets.data.OPENROUTER_API_KEY="sk-or-..." \
  --set config.values.model.default=openrouter/auto \
  --set config.values.model.provider=openrouter \
  --set config.values.model.api_key='${OPENROUTER_API_KEY}'

# Or use a preset from the examples directory (see below)
```

Open the dashboard:

```console
kubectl port-forward svc/hermes-hermes-agent 9119:9119
# visit http://127.0.0.1:9119
```

## Persistence: core vs. working directory

| Volume | Default mount | Holds | Value key |
| ------ | ------------- | ----- | --------- |
| Core state | `/opt/data` | config, sessions, memories, skills, logs | `persistence.data.*` |
| Working dir | `/opt/workspace` | git repos, data the agent operates on | `persistence.workspace.*` |

The chart injects `terminal.cwd: /opt/workspace` into `config.yaml` automatically
when the workspace volume is enabled, so the agent does its work on the second
disk while its identity/memory lives on the first. Set
`persistence.*.existingClaim` to reuse a pre-provisioned PVC, or
`persistence.*.retain: true` to keep volumes after `helm uninstall`.

## Configuration (`config.yaml`)

`config.enabled: true` renders `config.values` into a ConfigMap and an init
container seeds it into the data volume on first boot. `config.overwrite: false`
(default) means runtime/dashboard edits survive restarts.

`config.values` mirrors the Hermes `config.yaml` schema one-to-one — the chart
builds the whole file from it, so you rarely need a raw string. Supported
top-level sections: `model`, `custom_providers`, `providers`,
`fallback_providers`, `display`, `terminal`, `approvals`, `security`. Empty
sections are pruned automatically, so set only what you use, and `terminal.cwd`
is injected to the workspace mountPath for you.

**Secrets** are referenced as `${ENV_VAR}` placeholders inside `config.values`;
put the real value in `secrets.data` (or `secrets.existingSecret`). Hermes
expands the env var at runtime — secrets never land in the ConfigMap.

```yaml
config:
  values:
    model:
      default: anyrouter/agent
      provider: custom
      api_key: ${ANYROUTER_API_KEY}        # value lives in secrets.data
      base_url: ${ANYROUTER_API_BASE}
    custom_providers:
      - name: anyrouter
        base_url: https://anyrouter.dev/api/v1
        api_key: ${ANYROUTER_API_KEY}
        model: google/gemma-4-26b-a4b-it
    fallback_providers:
      - provider: openrouter
        model: openrouter/free
        base_url: https://openrouter.ai/api/v1
        api_mode: chat_completions
    display:
      personality: "You are a helpful assistant."
      busy_input_mode: steer
      busy_ack_enabled: true
secrets:
  data:
    ANYROUTER_API_KEY: "sk-..."
```

For full manual control, set `config.content` to a raw YAML string (it is used
verbatim and `config.values` is ignored; `terminal.cwd` is not auto-injected).
See the
[Hermes configuration docs](https://hermes-agent.nousresearch.com/docs/user-guide/configuration).

## Security

- Dashboard auth: HTTP Basic (`dashboard.auth.basicAuthUsername` +
  `HERMES_DASHBOARD_BASIC_AUTH_PASSWORD` secret), or OAuth/OIDC. `dashboard.insecure`
  disables the gate — never in production.
- API auth: `API_SERVER_KEY` (≥8 chars) is **required** when `apiServer.enabled`.
- Hermes blocks private/loopback IPs (SSRF protection). To let it reach
  in-cluster services, set `config.values.security.allow_private_urls: true`.
- See the [Hermes security docs](https://hermes-agent.nousresearch.com/docs/user-guide/security).

## Example presets

The chart includes example configurations for common use cases in the `examples/` directory:

| File | Use case |
| ---- | -------- |
| `minimal.yaml` | Just the gateway, no tools |
| `suggested.yaml` | Recommended: web search, browser, persona, fallback |
| `free-self-hosted.yaml` | SearXNG + local Chromium (no paid APIs) |
| `free-self-hosted-firecrawl.yaml` | Self-hosted Firecrawl for web tools |
| `custom-provider.yaml` | Custom OpenAI-compatible provider (anyrouter, vLLM, ollama) |
| `discord.yaml` | Discord bot integration |
| `discord-web.yaml` | Discord + web search |
| `discord-voice.yaml` | Discord + voice (TTS/STT) |
| `telegram.yaml` | Telegram bot integration |
| `voice.yaml` | Voice-enabled Hermes |
| `memory-tuned.yaml` | Reduced resource footprint |

Use them with:

```console
helm upgrade --install hermes duyet/hermes-agent \
  -n hermes-agent --create-namespace \
  -f https://raw.githubusercontent.com/duyet/charts/main/hermes-agent/examples/suggested.yaml \
  --set secrets.data.OPENROUTER_API_KEY="sk-or-..." \
  --set secrets.data.FIRECRAWL_API_KEY="fc-..."
```

## Upgrading

```console
helm upgrade hermes duyet/hermes-agent --set image.tag=v2026.6.5 --reuse-values
```

State persists on the PVCs; only the pod is replaced.

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| duyet | <me@duyet.net> | <https://github.com/duyet> |

## Source Code

* <https://github.com/NousResearch/hermes-agent>
* <https://hermes-agent.nousresearch.com/docs>

## Requirements

Kubernetes: `>=1.23.0-0`

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Affinity rules. |
| apiServer | object | `{"corsOrigins":"","enabled":true,"host":"0.0.0.0","port":8642}` | -------------------------------------------------------------------------- |
| apiServer.corsOrigins | string | `""` | Comma-separated CORS origins (e.g. "https://chat.example.com"). Empty disables cross-origin requests. |
| apiServer.enabled | bool | `true` | Enable the OpenAI-compatible API server. When true an API key is required (see secrets.API_SERVER_KEY or apiServer.existingKeySecret). |
| apiServer.host | string | `"0.0.0.0"` | Bind address inside the container. Must be 0.0.0.0 to be reachable via a Service; 127.0.0.1 would only serve localhost. |
| apiServer.port | int | `8642` | Container port for the gateway/API server. Also serves /health. |
| args | list | `[]` | Override the container args. Defaults to ["gateway", "run"]. |
| command | list | `[]` | Override the container command. Defaults to the image entrypoint. |
| commonLabels | object | `{}` | Extra labels applied to every rendered resource. |
| config | object | `{"content":"","enabled":true,"overwrite":false,"values":{"approvals":{"mode":"smart"},"custom_providers":[],"display":{},"fallback_providers":[],"model":{},"providers":{},"security":{"allow_private_urls":false},"terminal":{"backend":"local"}}}` | -------------------------------------------------------------------------- |
| config.content | string | `""` | Raw config.yaml content. ESCAPE HATCH: if set (non-empty), this string is used verbatim and `config.values` is ignored. terminal.cwd is NOT auto-injected here — set it yourself. Prefer `config.values` above. |
| config.enabled | bool | `true` | Manage config.yaml via this chart. When false, the chart writes nothing and you manage /opt/data/config.yaml yourself (e.g. via the dashboard). |
| config.overwrite | bool | `false` | Overwrite config.yaml on every pod start. false = seed once, then leave the file alone so dashboard/runtime edits survive restarts. |
| config.values | object | `{"approvals":{"mode":"smart"},"custom_providers":[],"display":{},"fallback_providers":[],"model":{},"providers":{},"security":{"allow_private_urls":false},"terminal":{"backend":"local"}}` | Structured config rendered into config.yaml, mirroring the Hermes config.yaml schema one-to-one. Empty top-level sections (model, providers, custom_providers, fallback_providers, display) are pruned automatically. `terminal.cwd` is injected automatically to the workspace mountPath when persistence.workspace.enabled. Reference secrets as `${ENV_VAR}` and put the value in secrets.data. See the Hermes docs: https://hermes-agent.nousresearch.com/docs/user-guide/configuration |
| config.values.approvals.mode | string | `"smart"` | Command-execution approval gating: smart, manual, or off. |
| config.values.custom_providers | list | `[]` | Register extra OpenAI-compatible providers, referenced by `name` from `model.provider: custom` or model strings like "<name>/<model>". |
| config.values.display | object | `{}` | Persona and chat UX (personality, busy_input_mode, busy_ack_enabled). |
| config.values.fallback_providers | list | `[]` | Fallback providers, tried in order when the primary model fails. |
| config.values.model | object | `{}` | Primary model: default (model string), provider (built-in id or "custom"), api_key, base_url. Empty by default so a bare install relies on provider env vars. |
| config.values.providers | object | `{}` | Per-provider overrides for built-in providers (api_key, base_url, ...). |
| config.values.security.allow_private_urls | bool | `false` | Allow the agent to reach private/loopback IPs (SSRF protection is on by default). |
| config.values.terminal.backend | string | `"local"` | Code-execution isolation backend: local, docker, ssh, modal, or daytona. `cwd` is injected automatically. |
| config.values.web | object | `{}` | Web search & extraction tools. Backend: firecrawl | searxng | parallel | tavily | exa. Can split search_backend and extract_backend across providers. |
| config.values.browser | object | `{}` | Browser automation (cloud providers or local Chromium via CDP). Requires `shm.enabled` for local Chromium. |
| config.values.code_execution | object | `{}` | Code-execution limits (mode: project|strict, timeout, max_tool_calls). |
| config.values.discord | object | `{}` | Discord guild behavior (require_mention, free_response_channels, auto_thread). Put DISCORD_BOT_TOKEN in secrets.data. |
| config.values.voice | object | `{}` | Voice input/output feature toggle (enabled: true/false). |
| config.values.tts | object | `{}` | Text-to-speech output (enabled: true/false, engine). |
| config.values.stt | object | `{}` | Speech-to-text input (enabled: true/false, engine). |
| config.values.file_read_max_chars | int | `100000` | Maximum characters the agent will read from a single file. |
| config.values.compression | object | `{}` | Context compression for long conversations (enabled, threshold). |
| config.values.max_concurrent_sessions | int | | Maximum concurrent sessions (limit varies by backend). |
| dashboard | object | `{"auth":{"basicAuthUsername":"","oauthClientId":"","oidcClientId":"","oidcIssuer":""},"enabled":true,"host":"0.0.0.0","insecure":false,"port":9119}` | -------------------------------------------------------------------------- |
| dashboard.auth.basicAuthUsername | string | `""` | HTTP Basic auth username. Username is non-secret and lives here; the password/secret live in the Secret (see secrets.HERMES_DASHBOARD_*). |
| dashboard.auth.oauthClientId | string | `""` | Nous Portal OAuth client id (non-secret). |
| dashboard.auth.oidcClientId | string | `""` | Self-hosted OIDC client id. |
| dashboard.auth.oidcIssuer | string | `""` | Self-hosted OIDC issuer URL. |
| dashboard.enabled | bool | `true` | Enable the Hermes web dashboard (sets HERMES_DASHBOARD=1). Runs in the same container, supervised by s6 — no sidecar needed. |
| dashboard.host | string | `"0.0.0.0"` | Bind address inside the container. |
| dashboard.insecure | bool | `false` | Disable the dashboard's auth gate so it binds on non-loopback (0.0.0.0). IMPORTANT (verified on a live cluster): current Hermes builds REFUSE to bind the dashboard to 0.0.0.0 unless an OAuth/OIDC auth provider is registered. Basic-auth credentials alone may not register a provider on every version. So to actually reach the dashboard over the Service you must EITHER configure OAuth/OIDC below, OR set insecure: true (only behind your own auth/private network — e.g. an authenticated Ingress). The gateway API on 8642 is unaffected and works regardless. |
| dashboard.port | int | `9119` | Container port for the dashboard. |
| extraContainers | list | `[]` | Extra sidecar containers. |
| extraEnv | list | `[]` | Extra plain (non-secret) environment variables as a name/value list. |
| extraEnvFrom | list | `[]` | Extra envFrom sources (configMapRef / secretRef). |
| extraInitContainers | list | `[]` | Extra init containers. |
| extraVolumeMounts | list | `[]` | Extra volume mounts on the main container. |
| extraVolumes | list | `[]` | Extra volumes. |
| fullnameOverride | string | `""` | Override the fully qualified app name. |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy (IfNotPresent, Always, Never). |
| image.repository | string | `"nousresearch/hermes-agent"` | The container image repository. |
| image.tag | string | `""` | Image tag. Defaults to the chart appVersion. Override this single value to upgrade Hermes (e.g. "v2026.6.5", "latest", or "main"). |
| imagePullSecrets | list | `[]` | Image pull secrets for private registries. |
| ingress | object | `{"annotations":{},"className":"","enabled":false,"hosts":[{"host":"hermes.local","paths":[{"backend":"dashboard","path":"/","pathType":"Prefix"}]}],"tls":[]}` | -------------------------------------------------------------------------- |
| ingress.annotations | object | `{}` | Ingress annotations. |
| ingress.className | string | `""` | Ingress class name. |
| ingress.enabled | bool | `false` | Enable an Ingress for the dashboard and/or API. |
| ingress.hosts | list | `[{"host":"hermes.local","paths":[{"backend":"dashboard","path":"/","pathType":"Prefix"}]}]` | Which backend each host path routes to: "dashboard" or "api". Hosts list. Each host routes its paths to the named backend port. |
| ingress.tls | list | `[]` | TLS configuration. |
| nameOverride | string | `""` | Override the chart name. |
| networkPolicy | object | `{"egress":{"allowDNS":true,"allowHTTPS":true,"enabled":true,"extraRules":[]},"enabled":false,"ingress":{"enabled":true,"fromNamespaces":[],"fromPods":[]}}` | -------------------------------------------------------------------------- |
| networkPolicy.egress.allowDNS | bool | `true` | Allow DNS resolution to kube-system (UDP/TCP 53). |
| networkPolicy.egress.allowHTTPS | bool | `true` | Allow outbound HTTPS (443) to the internet for LLM provider APIs. |
| networkPolicy.egress.enabled | bool | `true` | Restrict outbound traffic. Hermes needs DNS + HTTPS to reach LLM providers; those are allowed by default when this is enabled. |
| networkPolicy.egress.extraRules | list | `[]` | Additional egress rules appended verbatim (list of NetworkPolicy egress rule objects). |
| networkPolicy.enabled | bool | `false` | Create a NetworkPolicy to isolate Hermes. Requires a CNI that enforces NetworkPolicy (Calico, Cilium, etc.). |
| networkPolicy.ingress.enabled | bool | `true` | Restrict inbound traffic. When true, only the rules below are allowed. |
| networkPolicy.ingress.fromNamespaces | list | `[]` | Namespace selectors allowed to reach Hermes (empty = same namespace via podSelector only). Each item is a Kubernetes labelSelector matchLabels map. |
| networkPolicy.ingress.fromPods | list | `[]` | Pod selectors allowed to reach Hermes within allowed namespaces. |
| nodeSelector | object | `{}` | Node selector. |
| persistence | object | `{"data":{"accessModes":["ReadWriteOnce"],"annotations":{},"enabled":true,"existingClaim":"","mountPath":"/opt/data","retain":false,"size":"5Gi","storageClass":""},"workspace":{"accessModes":["ReadWriteOnce"],"annotations":{},"enabled":true,"existingClaim":"","mountPath":"/opt/workspace","retain":false,"size":"10Gi","storageClass":""}}` | -------------------------------------------------------------------------- |
| persistence.data.accessModes | list | `["ReadWriteOnce"]` | Access mode. Single-writer, so ReadWriteOnce is correct. |
| persistence.data.annotations | object | `{}` | Annotations for the core state PVC. |
| persistence.data.enabled | bool | `true` | Persist the core agent state volume. Strongly recommended; without it all sessions, memories, skills and config are lost on pod restart. |
| persistence.data.existingClaim | string | `""` | Use an existing PVC for core state instead of creating one. |
| persistence.data.mountPath | string | `"/opt/data"` | Mount path for core agent state. Maps to HERMES_HOME inside the container. Do not change unless you also set env HERMES_HOME. |
| persistence.data.retain | bool | `false` | Keep the PVC after `helm uninstall` (helm.sh/resource-policy: keep). |
| persistence.data.size | string | `"5Gi"` | Requested size for the core state volume. |
| persistence.data.storageClass | string | `""` | StorageClass for the core state PVC. "" uses the cluster default. |
| persistence.workspace.accessModes | list | `["ReadWriteOnce"]` | Access mode for the workspace PVC. |
| persistence.workspace.annotations | object | `{}` | Annotations for the workspace PVC. |
| persistence.workspace.enabled | bool | `true` | Persist a SEPARATE working-directory volume for the agent's projects, git checkouts and data. The chart points the agent's terminal.cwd here. |
| persistence.workspace.existingClaim | string | `""` | Use an existing PVC for the working directory instead of creating one. |
| persistence.workspace.mountPath | string | `"/opt/workspace"` | Mount path for the working directory (the agent's cwd). |
| persistence.workspace.retain | bool | `false` | Keep the PVC after `helm uninstall`. |
| persistence.workspace.size | string | `"10Gi"` | Requested size for the workspace volume. |
| persistence.workspace.storageClass | string | `""` | StorageClass for the workspace PVC. "" uses the cluster default. |
| podAnnotations | object | `{}` | Annotations added to the pod. A config/secret checksum is always added on top so config changes trigger a rolling restart automatically. |
| podDisruptionBudget | object | `{"enabled":false,"minAvailable":1}` | -------------------------------------------------------------------------- |
| podDisruptionBudget.enabled | bool | `false` | Create a PDB. With a single replica this mainly documents intent; set minAvailable: 0 to allow voluntary eviction during node drains. |
| podLabels | object | `{}` | Labels added to the pod. |
| podSecurityContext | object | `{"fsGroup":10000,"fsGroupChangePolicy":"OnRootMismatch","runAsGroup":0,"runAsUser":0,"seccompProfile":{"type":"RuntimeDefault"}}` | Pod-level security context. IMPORTANT: the Hermes image uses s6-overlay v3, which MUST start as root (uid 0) to fix /run permissions and set up supervision, then drops to the unprivileged hermes user (uid 10000) itself via s6-setuidgid. Forcing runAsNonRoot/runAsUser=10000 here breaks startup with:   "/run belongs to uid 0 instead of 10000 ... lacking the privileges to fix it". The agent process therefore runs as root only during s6 boot and as uid 10000 at runtime. fsGroup 10000 keeps the persistent volumes writable after the drop. (Verified on a live k3s cluster — see chart README.) |
| probes | object | `{"liveness":{"enabled":true,"failureThreshold":6,"httpGet":{"path":"/health","port":"api"},"initialDelaySeconds":30,"periodSeconds":30,"timeoutSeconds":5},"readiness":{"enabled":true,"failureThreshold":6,"httpGet":{"path":"/health","port":"api"},"initialDelaySeconds":15,"periodSeconds":15,"timeoutSeconds":5},"startup":{"enabled":true,"failureThreshold":30,"httpGet":{"path":"/health","port":"api"},"initialDelaySeconds":10,"periodSeconds":10,"timeoutSeconds":5}}` | -------------------------------------------------------------------------- |
| probes.liveness | object | `{"enabled":true,"failureThreshold":6,"httpGet":{"path":"/health","port":"api"},"initialDelaySeconds":30,"periodSeconds":30,"timeoutSeconds":5}` | Liveness probe. Disable if apiServer.enabled is false (no /health then). |
| probes.readiness | object | `{"enabled":true,"failureThreshold":6,"httpGet":{"path":"/health","port":"api"},"initialDelaySeconds":15,"periodSeconds":15,"timeoutSeconds":5}` | Readiness probe. |
| probes.startup | object | `{"enabled":true,"failureThreshold":30,"httpGet":{"path":"/health","port":"api"},"initialDelaySeconds":10,"periodSeconds":10,"timeoutSeconds":5}` | Startup probe (gives the agent time to migrate config/state on first run). |
| replicaCount | int | `1` | Number of replicas. Hermes is single-writer; values other than 1 are rejected unless you disable persistence. Do not change without external coordination. |
| resources | object | `{"limits":{"cpu":"2","memory":"4Gi"},"requests":{"cpu":"1","memory":"2Gi"}}` | Resource requests/limits. Hermes recommends 2 CPU / 2-4Gi for real use. |
| secrets | object | `{"data":{},"existingSecret":""}` | -------------------------------------------------------------------------- |
| secrets.data | object | `{}` | Key/value pairs rendered into a chart-managed Secret and injected as env vars via envFrom. Only non-empty values are rendered. Put any of:   ANTHROPIC_API_KEY, OPENAI_API_KEY, OPENROUTER_API_KEY, GOOGLE_API_KEY,   GROQ_API_KEY, DEEPSEEK_API_KEY, XAI_API_KEY, MINIMAX_API_KEY,   API_SERVER_KEY (>=8 chars, required when apiServer.enabled),   HERMES_DASHBOARD_BASIC_AUTH_PASSWORD, HERMES_DASHBOARD_BASIC_AUTH_SECRET,   HERMES_DASHBOARD_OAUTH_CLIENT_SECRET, TELEGRAM_BOT_TOKEN, ... |
| secrets.existingSecret | string | `""` | Use an existing Secret (referenced via envFrom) instead of the chart-managed one below. When set, the `secrets.data` map is ignored. |
| securityContext | object | `{"allowPrivilegeEscalation":false,"readOnlyRootFilesystem":false,"seccompProfile":{"type":"RuntimeDefault"}}` | Container-level security context. s6-overlay needs to chown /run and drop privileges at boot, so we cannot drop all Linux capabilities or enforce runAsNonRoot. no_new_privs (allowPrivilegeEscalation: false) is still safe because s6 only DROPS privileges. The agent runs unprivileged (uid 10000) after boot. |
| service | object | `{"annotations":{},"apiPort":8642,"dashboardPort":9119,"type":"ClusterIP"}` | -------------------------------------------------------------------------- |
| service.annotations | object | `{}` | Annotations for the Service. |
| service.apiPort | int | `8642` | Service port for the gateway/API server (maps to apiServer.port). |
| service.dashboardPort | int | `9119` | Service port for the dashboard (maps to dashboard.port). |
| service.type | string | `"ClusterIP"` | Service type (ClusterIP, NodePort, LoadBalancer). |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account. |
| serviceAccount.automountServiceAccountToken | bool | `false` | Auto-mount the API token. Hermes does not talk to the Kubernetes API, so this is disabled by default for least privilege. |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created. |
| serviceAccount.name | string | `""` | The name of the service account to use. Generated from fullname if empty. |
| serviceMonitor | object | `{"enabled":false,"interval":"30s","labels":{},"path":"/metrics","port":"api","scrapeTimeout":"10s"}` | -------------------------------------------------------------------------- |
| serviceMonitor.enabled | bool | `false` | Create a ServiceMonitor (requires the Prometheus Operator CRD to already exist in the cluster — the chart does not install it). |
| serviceMonitor.interval | string | `"30s"` | Scrape interval. |
| serviceMonitor.labels | object | `{}` | Extra labels (e.g. release: kube-prometheus-stack) so the operator selects this monitor. |
| serviceMonitor.path | string | `"/metrics"` | Scrape path. |
| serviceMonitor.port | string | `"api"` | Which port to scrape ("api" or "dashboard"). |
| serviceMonitor.scrapeTimeout | string | `"10s"` | Scrape timeout. |
| shm | object | `{"enabled":true,"sizeLimit":"1Gi"}` | Shared memory (/dev/shm) sizing for browser automation (Chromium needs it). Mounted as an in-memory emptyDir. |
| tolerations | list | `[]` | Tolerations. |
| topologySpreadConstraints | list | `[]` | Topology spread constraints. |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
