# Personal Setup Notes

Notas tras bootstrappear este fork en una Mac nueva (Apple Silicon, mayo 2026).
Recoge los problemas reales encontrados durante la instalación y los fixes que tuve que
aplicar — cosas que **no están** en el README original. Apunto a tener este archivo como
playbook para la próxima vez que estrene Mac (o le sirva a alguien del equipo).

---

## Bootstrap path que sí funcionó

```bash
# 1. Homebrew + dots (lo más limpio si ya tienes brew)
brew install sanurb/tap/dots
dots init           # pide consentimiento para instalar Nix + clonar repo

# 2. Tras instalar Nix, dots sale limpio. Abre NUEVA pestaña/ventana de Terminal
#    (Cmd+T) — la sesión actual no tiene `nix` en PATH todavía. Después:
dots init           # ahora clona el repo, corre el wizard y ofrece deploy

# 3. Si `dots apply` falla con "nh: not on PATH" (ocurre cuando se invoca desde
#    fuera del workspace), entra al devshell explícitamente:
cd ~/.dotfiles
nix develop -c dots apply
```

El wizard pregunta 6 cosas. Mis elecciones:

| Paso | Elegido |
|---|---|
| Shell | **Fish** (mejor experiencia interactiva, bien soportado por dots) |
| Terminal | **Ghostty** (nativo macOS, GPU-accelerated) |
| Font | Iosevka Nerd Font (sí, requerida para íconos) |
| Multiplexer | **Zellij** (descubrible, layouts en YAML) |
| Editor | Neovim con LSP + TreeSitter + dots config |
| Confirm | Yes |

---

## Fixes aplicados — los que faltan en el README original

### 1. Determinate Nix `trusted-users` (CRÍTICO para velocidad)

Sin esto, Nix ignora los caches binarios comunitarios (`nix-community.cachix.org`,
`colmena.cachix.org`) y **compila TODO desde fuente** — varias horas en lugar de
~10–15 min, y la Mac al 100% de CPU.

```bash
echo "extra-trusted-users = $(whoami)" | sudo tee /etc/nix/nix.custom.conf
sudo launchctl kickstart -k system/systems.determinate.nix-daemon
```

**Detalles importantes**:
- Escribir a `/etc/nix/nix.custom.conf`, NO a `/etc/nix/nix.conf` — el segundo lo regenera
  Determinate Nix en cada upgrade y se pierde tu cambio. Determinate ya hace
  `!include nix.custom.conf` automáticamente.
- El daemon se llama `systems.determinate.nix-daemon`, **no** `org.nixos.nix-daemon` como
  en docs del Nix oficial. El kickstart con el nombre equivocado da:
  `Could not find service "org.nixos.nix-daemon" in domain for system`.

### 2. Fish no recibe los paths de Nix automáticamente (macOS)

El installer de Determinate solo configura `/etc/zshrc` y `/etc/bashrc`. Cuando Fish
arranca desde una app GUI (Ghostty), no hereda esos paths. Resultado: `atuin`, `nix`,
y otros binarios de Nix aparecen como "Unknown command", con un stacktrace de
`_atuin_preexec` en cada Enter.

`~/.config/fish/conf.d/` es symlink al `/nix/store/`, así que no se puede agregar un
snippet ahí (read-only). Fix con **fish universal vars** (persiste en
`~/.config/fish/fish_variables`, escribible):

```fish
fish_add_path -U /Users/<usuario>/.nix-profile/bin
fish_add_path -U /nix/var/nix/profiles/default/bin
exec fish
```

### 3. Starship se rompe tras `cd` que dispara direnv

direnv des-setea `STARSHIP_SHELL` al activar el devshell del workspace. Como el shell
padre (probablemente bash de algún script de bootstrap macOS/Determinate) ya tenía
`STARSHIP_SHELL=bash`, fish hereda ese valor. starship lo lee, decide que es bash, y
renderiza el prompt con markers de bash (`\[\]` literales en pantalla).

**Fix permanente**: editar `config/fish/conf.d/starship.fish` para agregar un hook
`--on-event fish_prompt` que re-inicia starship si la variable no dice "fish":

```fish
function __ensure_starship_fish --on-event fish_prompt
    if test "$STARSHIP_SHELL" != "fish"
        starship init fish | source
    end
end

starship init fish | source
```

Importante: el check correcto es `!= "fish"`, NO `not set -q` (porque la variable sí
existe — solo tiene el valor equivocado).

### 4. Ghostty: dots doctor reporta falso positivo en macOS

`dots doctor` dice `✗ terminal = ghostty (ghostty not on PATH ...)`. Es esperado: en
macOS, Ghostty es un `.app` que vive en `/Applications/`, no un binario CLI en `$PATH`.
La app funciona perfecto desde Spotlight/Dock.

Si quieres `ghostty` como comando en la CLI (para usar `ghostty +list-keybinds` etc.):

```bash
mkdir -p ~/.local/bin
ln -sf /Applications/Ghostty.app/Contents/MacOS/ghostty ~/.local/bin/ghostty
```

---

## Customizaciones propias

### Prompt de starship — control gamer en lugar del bigote default

En `config/starship/starship.toml`, módulo `[character]`:

```toml
[character]
success_symbol = "[󰊴 ](fg:green)"
error_symbol = "[󰊴 ](fg:red)"
```

`󰊴` es el glyph de control moderno de Material Design Icons (Nerd Fonts). Verde si el
último comando fue exitoso, rojo si falló — la convención semántica del default.

Para probar otros íconos: https://www.nerdfonts.com/cheat-sheet (cualquier glyph del
catálogo entre los `[ ]`).

---

## Checklist para Mac nueva

- [ ] Homebrew instalado (`/opt/homebrew/bin/brew --version`)
- [ ] `brew install sanurb/tap/dots`
- [ ] `dots init` → consent install Nix → **abrir nueva shell** → `dots init` otra vez
- [ ] **Antes de `dots apply`**: agregar trusted-users a `nix.custom.conf` y kickstart daemon
- [ ] `cd ~/.dotfiles && nix develop -c dots apply` (o con direnv ya configurado)
- [ ] Agregar fish a `/etc/shells` si lo pide (`echo /Users/<user>/.nix-profile/bin/fish | sudo tee -a /etc/shells`)
- [ ] `fish_add_path -U /Users/<user>/.nix-profile/bin /nix/var/nix/profiles/default/bin`
- [ ] Verificar `dots doctor` — todo verde excepto el falso positivo de Ghostty
- [ ] Configurar Git identity (`git config --global user.name/user.email`)
- [ ] Generar SSH key (`ssh-keygen -t ed25519`) y registrar en GitHub
- [ ] Abrir Ghostty desde Spotlight — verificar que el prompt es bonito y los íconos se ven
