# OpenCode + OmO + Docker Model Runner on Windows

This setup runs:

- **OpenCode + OmO** inside an isolated Docker container.
- **Git + GitHub CLI (`gh`)** inside the same container.
- **Qwen3.5 9B Q8_0** through Docker Model Runner with NVIDIA GPU acceleration.
- Project files and configuration in persistent Docker volumes.

The OpenCode/OmO container does **not** receive direct GPU access, the Docker socket, your Windows home directory, or privileged access.

---

## 1. Verify Windows prerequisites

Open **PowerShell**:

```powershell
docker version
wsl --version
nvidia-smi
```

Update WSL:

```powershell
wsl --update
```

Optional GPU passthrough test:

```powershell
docker run --rm --gpus=all nvidia/cuda:12.8.1-base-ubuntu24.04 nvidia-smi
```

---

## 2. Enable Docker Model Runner

In Docker Desktop:

**Settings → AI**

Use:

```text
Docker Model Runner: Enabled
TCP Port: 12434
Bind address: Localhost (127.0.0.1)
CORS allowed origins: empty
GPU-backed inference: Enabled
```

Or enable it from PowerShell:

```powershell
docker desktop enable model-runner --tcp 12434
```

Verify:

```powershell
docker model status
```

---

## 3. Pull Qwen3.5 9B Q8_0

Docker Model Runner's default `llama.cpp` backend requires a **GGUF** model.

Pull the Q8_0 quantization:

```powershell
docker model pull hf.co/bartowski/Qwen_Qwen3.5-9B-GGUF:Q8_0
```

List installed models:

```powershell
docker model ls
```

Test the model:

```powershell
docker model run hf.co/bartowski/Qwen_Qwen3.5-9B-GGUF:Q8_0 "Reply only with: OK"
```

Check GPU usage while the model is loaded:

```powershell
nvidia-smi
```

Optional: configure a specific context size:

```powershell
docker model configure --context-size 32768 hf.co/bartowski/Qwen_Qwen3.5-9B-GGUF:Q8_0
```

---

## 4. Create the OpenCode + OmO Docker project

Create a directory:

```powershell
mkdir C:\docker\omo
cd C:\docker\omo
```

The directory will contain:

```text
C:\docker\omo
├── Dockerfile
└── compose.yaml
```

---

## 5. Create `Dockerfile`

Already done. See Dockerfile in project's root.
> Note: The provider flags above mean OmO is installed without configuring paid cloud-provider subscriptions. Add/change them later if required.

---

## 6. Create `compose.yaml`

Already done. See compose.yaml in project's root.

---

## 7. Build the image

From PowerShell:

```powershell
cd C:\docker\omo
docker compose build
```

Start it:

```powershell
docker compose up -d
```

Check status:

```powershell
docker compose ps
```

---

## 8. Open a terminal inside the container

```powershell
docker exec -it omo bash
```

Verify the tools:

```bash
git --version
gh --version
node --version
npm --version
bun --version
opencode --version
tmux -V
```

---

## 9. Authenticate GitHub CLI

Inside the container:

```bash
gh auth login --hostname github.com --git-protocol https --web
```

Follow the device/browser authentication flow on Windows.

Then configure Git to use GitHub CLI authentication:

```bash
gh auth setup-git
```

Verify:

```bash
gh auth status
```

Configure your Git commit identity:

```bash
git config --global user.name "YOUR NAME"
git config --global user.email "YOUR_GITHUB_EMAIL"
```

Verify:

```bash
git config --global --list
```

The GitHub authentication and Git configuration are stored in the persistent `omo-home` Docker volume, not in the image.

---

## 10. Verify Docker Model Runner from inside the container

Still inside the `omo` container:

```bash
curl http://model-runner.docker.internal/engines/v1/models
```

If your Docker Model Runner version exposes the newer alias instead, test:

```bash
curl http://model-runner.docker.internal/v1/models
```

The response should include the Qwen model.

---

## 11.1. Configure OpenCode to use Docker Model Runner

Create the global OpenCode configuration directory:

```bash
mkdir -p ~/.config/opencode
```

First obtain the exact model ID:

```bash
curl -s http://model-runner.docker.internal/engines/v1/models | jq
```

Then create/edit:

```bash
nano ~/.config/opencode/opencode.json
```

If `nano` is not installed:

```bash
apt-get update && apt-get install -y nano
```

Use this configuration:

```json
{
  "$schema": "https://opencode.ai/config.json",

  "plugin": [
    "oh-my-openagent@latest"
  ],

  "provider": {
    "dmr": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Docker Model Runner",
      "options": {
        "baseURL": "http://model-runner.docker.internal/engines/v1"
      },
      "models": {
        "huggingface.co/bartowski/openai_gpt-oss-20b-gguf:Q4_K_M": {
          "name": "openai_gpt oss 20B Q4_K_M"
        }
      }
    }
  },

  "model": "dmr/huggingface.co/bartowski/openai_gpt-oss-20b-gguf:Q4_K_M"
}
```

If the `/models` API reports a different model ID, replace the model key and default model value with that exact ID.

## 11.2. Configure Omo to disable tools that do not work
Some tools and MCPs may not work depending on your local model. For example, for `bartowski/openai_gpt-oss-20b-gguf:Q4_K_M` the `websearch api mcp` throws a parsing error when making any request to the AI.
```bash
nano ~/.omo/omo.jsonc
```
Add this block right below the schema: 
```json
"$schema": "https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/dev/assets/omo.schema.json",`
"disabled_mcps": [
  "websearch",
],
// rest of config
```
---

## 12. Start OpenCode

Inside the container:

```bash
cd /workspace
opencode
```

Inside the OpenCode TUI, use:

```text
/models
```

Confirm that:

```text
Docker Model Runner
└── openai_gpt oss 20B Q4_K_M
```

is available.

---

## 13. Clone a project

From inside the container:

```bash
cd /workspace
gh repo clone OWNER/REPOSITORY
cd REPOSITORY
```

Or:

```bash
git clone https://github.com/OWNER/REPOSITORY.git
cd REPOSITORY
```

Verify Git access:

```bash
git status
git remote -v
```

Test GitHub CLI:

```bash
gh repo view
```

---

## 14. Run OpenCode + OmO on a project

From the repository:

```bash
opencode
```

Normal OmO use:

```text
ultrawork <your task>
```

or:

```text
ulw <your task>
```

Example:

```text
ulw inspect this repository, run the tests, identify the cause of the failing authentication tests, implement the fix, verify it, and keep the git working tree organized
```

Git and `gh` are available to OmO inside the container.

> OmO's delegated/category agents can have their own model-routing configuration. Making Qwen the OpenCode session model does not necessarily make every OmO subagent use Qwen. Configure OmO's model/category routing separately if you want all delegated work to use local models.

---

# Daily usage

## Start the environment

PowerShell:

```powershell
cd C:\docker\omo
docker compose up -d
docker exec -it omo bash
```

Then inside:

```bash
cd /workspace/YOUR_PROJECT
opencode
```

## Stop the environment

PowerShell:

```powershell
docker compose stop
```

## Start it again

```powershell
docker compose start
```

Stopping the container does **not** delete installed state or Docker volumes.

---

# Rebuilding after Dockerfile changes

```powershell
cd C:\docker\omo
docker compose build --no-cache
docker compose up -d --force-recreate
```

Your persistent volumes remain:

```text
omo-workspace
omo-home
```

List them:

```powershell
docker volume ls
```

---

# Updating OpenCode / OmO

Because OpenCode and OmO are part of the Docker image, the preferred method is to rebuild the image.

```powershell
docker compose build --pull --no-cache
docker compose up -d --force-recreate
```

If an OmO update changes files stored under `/root`, the existing `omo-home` volume can retain the older user-level configuration. Run the OmO installer once inside the container if a migration/update requires it:

```bash
bunx oh-my-openagent install
```

Do not put credentials into the Dockerfile.

---

# Model Runner maintenance

List models:

```powershell
docker model ls
```

Check Model Runner:

```powershell
docker model status
```

List currently loaded models:

```powershell
docker model ps
```

Unload Qwen:

```powershell
docker model unload hf.co/bartowski/Qwen_Qwen3.5-9B-GGUF:Q8_0
```

Run/test it again:

```powershell
docker model run hf.co/bartowski/Qwen_Qwen3.5-9B-GGUF:Q8_0 "Reply with OK"
```

Check Model Runner logs:

```powershell
docker model logs
```

---

# Useful Docker commands

Enter the running container:

```powershell
docker exec -it omo bash
```

View logs:

```powershell
docker compose logs -f omo
```

Restart:

```powershell
docker compose restart omo
```

Stop:

```powershell
docker compose stop
```

Remove only the container/network:

```powershell
docker compose down
```

The named volumes remain.

---

# Reset the OpenCode/OmO home state

**Warning:** this deletes GitHub authentication, Git configuration, OpenCode configuration, OmO state, and other files stored in `omo-home`.

First:

```powershell
docker compose down
```

Find the exact volume name:

```powershell
docker volume ls
```

Then remove only the home volume, for example:

```powershell
docker volume rm omo_omo-home
```

Recreate the container:

```powershell
docker compose up -d
```

Your separate `omo-workspace` volume remains intact.

---

# Full reset

**Warning: this also deletes all projects stored in `/workspace`.**

```powershell
docker compose down -v
```

Then rebuild:

```powershell
docker compose build --no-cache
docker compose up -d
```

---

# Security rules for this environment

Keep these rules:

- Do not mount `/var/run/docker.sock`.
- Do not use `--privileged`.
- Do not mount `C:\` or your Windows home directory.
- Do not mount your normal Windows SSH keys.
- Keep GitHub credentials inside the Docker volume.
- Prefer repository-scoped credentials where practical.
- Do not put API keys or tokens in the Dockerfile.
- Keep Docker Model Runner outside the agent container; the agent should access it only over HTTP.
- Persist source code/configuration, not the whole host filesystem.
