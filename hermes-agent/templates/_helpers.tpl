{{/*
Expand the name of the chart.
*/}}
{{- define "hermes-agent.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "hermes-agent.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "hermes-agent.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "hermes-agent.labels" -}}
helm.sh/chart: {{ include "hermes-agent.chart" . }}
{{ include "hermes-agent.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: hermes-agent
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "hermes-agent.selectorLabels" -}}
app.kubernetes.io/name: {{ include "hermes-agent.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "hermes-agent.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "hermes-agent.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Name of the Secret holding credentials (chart-managed or user-provided).
*/}}
{{- define "hermes-agent.secretName" -}}
{{- if .Values.secrets.existingSecret }}
{{- .Values.secrets.existingSecret }}
{{- else }}
{{- include "hermes-agent.fullname" . }}
{{- end }}
{{- end }}

{{/*
Name of the data (core agent state) PersistentVolumeClaim.
*/}}
{{- define "hermes-agent.dataClaimName" -}}
{{- if .Values.persistence.data.existingClaim }}
{{- .Values.persistence.data.existingClaim }}
{{- else }}
{{- printf "%s-data" (include "hermes-agent.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Name of the workspace (working directory) PersistentVolumeClaim.
*/}}
{{- define "hermes-agent.workspaceClaimName" -}}
{{- if .Values.persistence.workspace.existingClaim }}
{{- .Values.persistence.workspace.existingClaim }}
{{- else }}
{{- printf "%s-workspace" (include "hermes-agent.fullname" .) }}
{{- end }}
{{- end }}

{{/*
The agent working directory path (terminal.cwd). When the workspace volume is
enabled, the agent operates inside its mountPath; otherwise it falls back to the
core data home.
*/}}
{{- define "hermes-agent.workingDir" -}}
{{- if .Values.persistence.workspace.enabled }}
{{- .Values.persistence.workspace.mountPath }}
{{- else }}
{{- .Values.persistence.data.mountPath }}
{{- end }}
{{- end }}

{{/*
Render the agent config.yaml body from .Values.config.values.
- Injects terminal.cwd -> the workspace mountPath when the workspace volume is
  enabled, so the agent operates inside its persistent working directory.
- Prunes empty top-level sections (model, providers, custom_providers,
  fallback_providers, display, ...) so unset optional blocks never reach the
  rendered config.yaml.
Secrets are referenced as ${ENV_VAR} placeholders in the values and expanded by
Hermes at runtime from the chart-managed Secret (see .Values.secrets) — they are
never written into this ConfigMap.
*/}}
{{- define "hermes-agent.config" -}}
{{- $src := deepCopy .Values.config.values -}}
{{- if .Values.githubMcp.enabled -}}
{{- $mcps := default (dict) (get $src "mcp_servers") -}}
{{- $_ := set $mcps "github" (dict "command" (printf "%s/.local/bin/gh-mcp-wrapper.sh" .Values.persistence.data.mountPath) "args" (list "stdio") "env" (dict "GITHUB_TOOLSETS" .Values.githubMcp.toolsets)) -}}
{{- $_ := set $src "mcp_servers" $mcps -}}
{{- end -}}
{{- if .Values.n8nMcp.enabled -}}
{{- $mcps := default (dict) (get $src "mcp_servers") -}}
{{- $_ := set $mcps "n8n" (dict "command" "/opt/mcp/n8n/repo/.venv/bin/python" "args" (list "/opt/mcp/n8n/repo/server.py") "env" (dict "N8N_BASE_URL" .Values.n8nMcp.baseUrl "N8N_API_KEY" "${N8N_API_KEY}")) -}}
{{- $_ := set $src "mcp_servers" $mcps -}}
{{- end -}}
{{- if .Values.browserSidecar.enabled -}}
{{- $browser := default (dict) (get $src "browser") -}}
{{- if not (get $browser "cdp_url") -}}
{{- $_ := set $browser "cdp_url" "http://localhost:9222" -}}
{{- $_ := set $src "browser" $browser -}}
{{- end -}}
{{- end -}}
{{- if .Values.persistence.workspace.enabled -}}
{{- $terminal := default (dict) (get $src "terminal") -}}
{{- $_ := set $terminal "cwd" .Values.persistence.workspace.mountPath -}}
{{- $_ := set $src "terminal" $terminal -}}
{{- end -}}
{{- $out := dict -}}
{{- range $k, $v := $src -}}
{{- /* Prune only blank containers/strings; keep meaningful false/0 scalars. */ -}}
{{- $blank := or
      (kindIs "invalid" $v)
      (and (kindIs "map" $v) (eq (len (keys $v)) 0))
      (and (kindIs "slice" $v) (eq (len $v) 0))
      (and (kindIs "string" $v) (eq $v "")) -}}
{{- if not $blank -}}
{{- $_ := set $out $k $v -}}
{{- end -}}
{{- end -}}
{{- toYaml $out -}}
{{- end }}

{{/*
Feature toggle: init containers.
Returns a YAML list of init containers based on which feature toggles are enabled.
*/}}
{{- define "hermes-agent.feature-init-containers" -}}
{{- if .Values.config.resolveEnv }}
- name: resolve-config-env
  image: alpine:3.20
  command: ["sh", "-c"]
  args:
    - |
      set -u
      CFG={{ .Values.persistence.data.mountPath }}/config.yaml
      if [ -f "$CFG" ]; then
        echo "Resolving env vars in $CFG..."
        {{- range .Values.config.resolveEnv }}
        sed -i "s|\${{ . }}|${{ . }}|g" "$CFG"
        {{- end }}
        echo "Done."
      else
        echo "$CFG not found, skipping."
      fi
  env:
    {{- range .Values.config.resolveEnv }}
    - name: {{ . }}
      valueFrom:
        secretKeyRef:
          name: {{ include "hermes-agent.secretName" $ }}
          key: {{ . }}
    {{- end }}
  volumeMounts:
    - name: data
      mountPath: {{ $.Values.persistence.data.mountPath }}
{{- end }}
{{- if .Values.githubMcp.enabled }}
- name: fetch-github-mcp
  image: alpine:3.20
  command: ["sh", "-c"]
  args:
    - |
      set -eu
      ver={{ .Values.githubMcp.version | quote }}
      cd /mcp-bin
      if [ ! -x github-mcp-server ]; then
        echo "Downloading github-mcp-server ${ver}..."
        wget -qO- "https://github.com/github/github-mcp-server/releases/download/${ver}/github-mcp-server_Linux_x86_64.tar.gz" \
          | tar xz github-mcp-server
        chmod +x github-mcp-server
      fi
      ./github-mcp-server --version || true
  volumeMounts:
    - name: github-mcp-bin
      mountPath: /mcp-bin
{{- end }}
{{- if .Values.n8nMcp.enabled }}
- name: fetch-n8n-mcp
  image: python:3.12-slim
  command: ["bash", "-c"]
  args:
    - |
      set -eu
      apt-get update -qq && apt-get install -y -qq git >/dev/null 2>&1
      cd /mcp-n8n
      if [ ! -d repo/.venv ]; then
        echo "Setting up hermes-n8n-mcp..."
        git clone --depth 1 https://github.com/CyberSamuraiX/hermes-n8n-mcp.git repo
        python -m venv repo/.venv
        repo/.venv/bin/pip install -q -r repo/requirements.txt
      fi
      echo "n8n MCP server ready"
  volumeMounts:
    - name: n8n-mcp-bin
      mountPath: /mcp-n8n
{{- end }}
{{- if .Values.clusterTools.enabled }}
- name: install-cluster-tools
  image: alpine:3.20
  command: ["sh", "-c"]
  args:
    - |
      set -u
      KVER={{ .Values.clusterTools.kubectlVersion | quote }}
      HVER={{ .Values.clusterTools.helmVersion | quote }}
      GVER={{ .Values.clusterTools.ghVersion | quote }}
      mkdir -p {{ .Values.persistence.data.mountPath }}/.local/bin
      cd {{ .Values.persistence.data.mountPath }}/.local/bin
      if [ ! -x kubectl ]; then
        echo "Downloading kubectl ${KVER}..."
        wget -q "https://dl.k8s.io/release/${KVER}/bin/linux/amd64/kubectl" -O kubectl && chmod +x kubectl || echo "kubectl download failed"
      fi
      if [ ! -x helm ]; then
        echo "Downloading helm ${HVER}..."
        wget -qO- "https://get.helm.sh/helm-${HVER}-linux-amd64.tar.gz" | tar xz -C /tmp linux-amd64/helm \
          && mv /tmp/linux-amd64/helm helm && chmod +x helm || echo "helm download failed"
      fi
      if [ ! -x gh ]; then
        echo "Downloading gh ${GVER}..."
        wget -qO /tmp/gh.tar.gz "https://github.com/cli/cli/releases/download/${GVER}/gh_${GVER#v}_linux_amd64.tar.gz" \
          && tar xzf /tmp/gh.tar.gz -C /tmp && mv /tmp/gh_${GVER#v}_linux_amd64/bin/gh gh && chmod +x gh \
          || echo "gh download failed"
        rm -f /tmp/gh.tar.gz
      fi
      ./kubectl version --client 2>/dev/null || true
      ./helm version --short 2>/dev/null || true
      ./gh --version 2>/dev/null || true
      # Coding agents
      if ! command -v claude >/dev/null 2>&1; then
        echo "Installing Claude Code..."
        npm install -g @anthropic-ai/claude-code 2>/dev/null && ln -sf $(which claude) {{ .Values.persistence.data.mountPath }}/.local/bin/claude || echo "claude install skipped"
      fi
      if [ ! -x opencode ]; then
        echo "Installing opencode..."
        wget -qO /tmp/opencode.tar.gz "https://github.com/sst/opencode/releases/latest/download/opencode-linux-x64-musl.tar.gz" \
          && tar xzf /tmp/opencode.tar.gz -C /tmp && mv /tmp/opencode opencode && chmod +x opencode \
          || echo "opencode install skipped"
        rm -f /tmp/opencode.tar.gz
      fi
      ./opencode version 2>/dev/null || true
      {{- if .Values.clusterTools.githubAppScripts }}

      # --- GitHub App auth helpers ---
      cat > mint-gh-token.py <<'PYEOF'
      #!/opt/hermes/.venv/bin/python3
      import os, sys, time, json, calendar, urllib.request, pathlib
      import jwt
      app = os.environ["GITHUB_APP_ID"]
      inst = os.environ["GITHUB_APP_INSTALLATION_ID"]
      key = os.environ["GITHUB_APP_PRIVATE_KEY"]
      cache = pathlib.Path("{{ .Values.persistence.data.mountPath }}/.cache/gh-token.json")
      try:
          d = json.loads(cache.read_text())
          if d["exp"] - time.time() > 300:
              print(d["token"]); sys.exit(0)
      except Exception:
          pass
      now = int(time.time())
      j = jwt.encode({"iat": now - 60, "exp": now + 540, "iss": app}, key, algorithm="RS256")
      req = urllib.request.Request(
          f"https://api.github.com/app/installations/{inst}/access_tokens",
          method="POST",
          headers={"Accept": "application/vnd.github+json", "User-Agent": "hermes-agent",
                   "Authorization": f"Bearer {j}"})
      r = json.load(urllib.request.urlopen(req))
      exp = calendar.timegm(time.strptime(r["expires_at"], "%Y-%m-%dT%H:%M:%SZ"))
      cache.parent.mkdir(parents=True, exist_ok=True)
      cache.write_text(json.dumps({"token": r["token"], "exp": exp})); cache.chmod(0o600)
      print(r["token"])
      PYEOF
      cat > gh-cred.sh <<'SHEOF'
      #!/bin/sh
      [ "$1" = "get" ] || exit 0
      echo "username=x-access-token"
      echo "password=$({{ .Values.persistence.data.mountPath }}/.local/bin/mint-gh-token.py)"
      SHEOF
      cat > gh-mcp-wrapper.sh <<'SHEOF'
      #!/bin/sh
      GITHUB_PERSONAL_ACCESS_TOKEN="$({{ .Values.persistence.data.mountPath }}/.local/bin/mint-gh-token.py)"
      export GITHUB_PERSONAL_ACCESS_TOKEN
      exec /opt/mcp/bin/github-mcp-server "$@"
      SHEOF
      chmod 0755 mint-gh-token.py gh-cred.sh gh-mcp-wrapper.sh
      echo "wrote github-app helper scripts"
      # Authenticate gh CLI with the GitHub App token
      TOKEN="$({{ .Values.persistence.data.mountPath }}/.local/bin/mint-gh-token.py 2>/dev/null)"
      if [ -n "$TOKEN" ]; then
        echo "$TOKEN" | gh auth login --with-token 2>/dev/null && echo "gh authenticated" || echo "gh auth skipped"
      fi
      {{- end }}
  securityContext:
    {{- toYaml $.Values.securityContext | nindent 12 }}
  volumeMounts:
    - name: data
      mountPath: {{ .Values.persistence.data.mountPath }}
    {{- if .Values.githubMcp.enabled }}
    - name: github-mcp-bin
      mountPath: /opt/mcp/bin
    {{- end }}
{{- end }}
{{- if .Values.devTools.enabled }}
- name: install-dev-tools
  image: python:3.12-slim
  command: ["bash", "-c"]
  args:
    - |
      set -eu
      # glibc Debian base: uv tool install needs a working Python interpreter.
      # alpine/musl can neither run uv's managed Pythons (glibc-only) nor install
      # most wheels (no musl builds), so every pythonTools call silently failed.
      # wget/unzip for uv+bun archives; nodejs+npm for pnpm and nodeTools.
      apt-get update -qq >/dev/null 2>&1
      apt-get install -y -qq wget unzip nodejs npm >/dev/null 2>&1
      DATA={{ .Values.persistence.data.mountPath }}
      BIN="$DATA/.local/bin"
      mkdir -p "$BIN"
      # All tool bins must land on the hermes container PATH, which includes
      # $DATA/.local/bin. Route every installer there:
      export HOME="$DATA"                 # uv/npm default ~/.local/bin → $BIN
      export XDG_BIN_HOME="$BIN"          # uv tool bins → $BIN explicitly
      export NPM_CONFIG_PREFIX="$DATA/.local"  # npm global bins live in $PREFIX/bin = $BIN
      export PATH="$BIN:$PATH"

      if [ ! -x "$BIN/uv" ]; then
        echo "Installing uv..."
        wget -qO- "https://github.com/astral-sh/uv/releases/latest/download/uv-x86_64-unknown-linux-gnu.tar.gz" \
          | tar xz -C /tmp
        mv /tmp/uv-*/uv "$BIN/uv"
        mv /tmp/uv-*/uvx "$BIN/uvx" 2>/dev/null || true
        chmod +x "$BIN/uv" "$BIN/uvx" 2>/dev/null || true
      fi

      if [ ! -x "$BIN/bun" ]; then
        echo "Installing bun..."
        wget -qO /tmp/bun.zip "https://github.com/oven-sh/bun/releases/latest/download/bun-linux-x64.zip"
        unzip -o /tmp/bun.zip -d /tmp >/dev/null 2>&1
        mv /tmp/bun-linux-x64/bun "$BIN/bun" && chmod +x "$BIN/bun"
        rm -rf /tmp/bun.zip /tmp/bun-linux-x64
      fi

      # pnpm: installed via npm (its standalone binary asset was removed in v11).
      # NPM_CONFIG_PREFIX points global bins at $BIN so `pnpm` is on PATH.
      if [ ! -x "$BIN/pnpm" ]; then
        echo "Installing pnpm..."
        npm install -g pnpm >/dev/null 2>&1 || echo "pnpm skipped"
      fi

      # Python CLI tools (uv-managed isolated envs, bins symlinked into $BIN).
      {{- range .Values.devTools.pythonTools }}
      "$BIN/uv" tool install {{ . }} >/dev/null 2>&1 || echo "uv tool {{ . }} skipped"
      {{- end }}

      # Node CLI tools (npm global, bins land in $BIN via NPM_CONFIG_PREFIX).
      {{- range .Values.devTools.nodeTools }}
      npm install -g {{ . }} >/dev/null 2>&1 || echo "npm {{ . }} skipped"
      {{- end }}

      echo "dev tools ready:"
      ls -1 "$BIN"
  securityContext:
    {{- toYaml $.Values.securityContext | nindent 12 }}
  volumeMounts:
    - name: data
      mountPath: {{ .Values.persistence.data.mountPath }}
{{- end }}
{{- if .Values.gitSetup.enabled }}
- name: git-setup
  image: alpine:3.20
  command: ["sh", "-c"]
  args:
    - |
      set -u
      apk add --no-cache git >/dev/null 2>&1
      HOME={{ .Values.persistence.workspace.mountPath }}
      git config --global --add safe.directory '*'
      git config --global user.name {{ .Values.gitSetup.userName | quote }}
      git config --global user.email {{ .Values.gitSetup.userEmail | quote }}
      {{- if .Values.gitSetup.credentialHelper }}
      git config --global credential.helper {{ .Values.gitSetup.credentialHelper | quote }}
      {{- end }}
      echo "git config set"
  volumeMounts:
    - name: workspace
      mountPath: {{ .Values.persistence.workspace.mountPath }}
{{- end }}
{{- if .Values.emailSkill.enabled }}
- name: install-himalaya
  image: alpine:3.20
  command: ["sh", "-c"]
  args:
    - |
      set -eu
      mkdir -p {{ .Values.persistence.data.mountPath }}/.local/bin {{ .Values.persistence.data.mountPath }}/.config/himalaya
      cd {{ .Values.persistence.data.mountPath }}/.local/bin
      if [ ! -x himalaya ]; then
        echo "Installing himalaya CLI..."
        wget -qO- https://github.com/pimalaya/himalaya/releases/latest/download/himalaya.x86_64-linux.tgz \
          | tar xzf - himalaya
        chmod +x himalaya
      fi
      ./himalaya --version || true
      cat > {{ .Values.persistence.data.mountPath }}/.config/himalaya/config.toml <<TOML
      [accounts.{{ .Values.emailSkill.accountName }}]
      email = "${EMAIL_ADDRESS}"
      display-name = {{ .Values.emailSkill.displayName | quote }}
      default = true

      backend.type = "imap"
      backend.host = {{ .Values.emailSkill.imap.host | quote }}
      backend.port = {{ .Values.emailSkill.imap.port }}
      backend.encryption.type = {{ .Values.emailSkill.imap.encryption | quote }}
      backend.login = "${EMAIL_ADDRESS}"
      backend.auth.type = "password"
      backend.auth.raw = "${EMAIL_PASSWORD}"

      message.send.backend.type = "smtp"
      message.send.backend.host = {{ .Values.emailSkill.smtp.host | quote }}
      message.send.backend.port = {{ .Values.emailSkill.smtp.port }}
      message.send.backend.encryption.type = {{ .Values.emailSkill.smtp.encryption | quote }}
      message.send.backend.login = "${EMAIL_ADDRESS}"
      message.send.backend.auth.type = "password"
      message.send.backend.auth.raw = "${EMAIL_PASSWORD}"

      {{- range $key, $val := .Values.emailSkill.folderAliases }}
      folder.aliases.{{ $key }} = {{ $val | quote }}
      {{- end }}
      TOML
      chmod 600 {{ .Values.persistence.data.mountPath }}/.config/himalaya/config.toml
      echo "himalaya configured"
  env:
    - name: EMAIL_ADDRESS
      valueFrom:
        secretKeyRef:
          name: {{ include "hermes-agent.secretName" . }}
          key: EMAIL_ADDRESS
    - name: EMAIL_PASSWORD
      valueFrom:
        secretKeyRef:
          name: {{ include "hermes-agent.secretName" . }}
          key: EMAIL_PASSWORD
  volumeMounts:
    - name: data
      mountPath: {{ .Values.persistence.data.mountPath }}
{{- end }}
{{- end }}

{{/*
Browser sidecar container (Chromium for CDP-based browser automation).
When browserSidecar.enabled, injects a chromium container that shares the
pod's /dev/shm and exposes CDP on localhost:9222. Also auto-injects
browser.cdp_url into the agent config.

NOTE: the chromedp/headless-shell image entrypoint already sets
--remote-debugging-port=9223 internally and runs socat to forward
9222→9223. Do NOT pass --remote-debugging-port in args or both chromium
and socat will fight over port 9222 (bind() EADDRINUSE).
*/}}
{{- define "hermes-agent.browser-sidecar" -}}
{{- if .Values.browserSidecar.enabled }}
- name: chromium
  image: {{ .Values.browserSidecar.image | quote }}
  imagePullPolicy: {{ .Values.browserSidecar.imagePullPolicy }}
  args:
    - --no-sandbox
    - --disable-gpu
    - --disable-dev-shm-usage
  ports:
    - containerPort: 9222
      protocol: TCP
  resources:
    {{- toYaml .Values.browserSidecar.resources | nindent 4 }}
  volumeMounts:
    - name: dshm
      mountPath: /dev/shm
{{- end }}
{{- end }}

{{/*
Feature toggle: volumes.
Returns a YAML list of additional volumes based on feature toggles.
*/}}
{{- define "hermes-agent.feature-volumes" -}}
{{- if .Values.githubMcp.enabled }}
- name: github-mcp-bin
  emptyDir: {}
{{- end }}
{{- if .Values.n8nMcp.enabled }}
- name: n8n-mcp-bin
  emptyDir: {}
{{- end }}
{{- range .Values.hostMounts }}
- name: {{ .name }}
  hostPath:
    path: {{ .hostPath }}
    type: Directory
{{- end }}
{{- end }}

{{/*
Feature toggle: volume mounts.
Returns a YAML list of additional volume mounts based on feature toggles.
*/}}
{{- define "hermes-agent.feature-volume-mounts" -}}
{{- if .Values.githubMcp.enabled }}
- name: github-mcp-bin
  mountPath: /opt/mcp/bin
{{- end }}
{{- if .Values.n8nMcp.enabled }}
- name: n8n-mcp-bin
  mountPath: /opt/mcp/n8n
{{- end }}
{{- range .Values.hostMounts }}
- name: {{ .name }}
  mountPath: {{ .mountPath }}
{{- end }}
{{- end }}

{{/*
Ingress API version detection.
*/}}
{{- define "hermes-agent.ingressApiVersion" -}}
{{- $kubeVersion := .Capabilities.KubeVersion.GitVersion -}}
{{- if semverCompare ">=1.19-0" $kubeVersion -}}
networking.k8s.io/v1
{{- else if semverCompare ">=1.14-0" $kubeVersion -}}
networking.k8s.io/v1beta1
{{- else -}}
extensions/v1beta1
{{- end }}
{{- end }}
