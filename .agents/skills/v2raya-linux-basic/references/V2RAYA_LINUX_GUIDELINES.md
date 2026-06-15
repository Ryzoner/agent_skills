# V2RAYA_LINUX_GUIDELINES

## Цель
- Поднять `v2rayA` на Linux и перейти на дальнейшее управление через UI.
- Настроить стабильный `TUN` + `RoutingA` профиль для разработки/медиа.
- Использовать Outline access keys в `v2rayA` без лишних конвертаций.

## Быстрый helper-скрипт
```bash
# preview (safe default, без выполнения install-команд)
bash scripts/v2raya-install.sh

# принудительный профиль
bash scripts/v2raya-install.sh --distro arch

# выполнить установку реально
bash scripts/v2raya-install.sh --apply
```

## 1) Установка и запуск

### Arch Linux
```bash
yay -S v2raya xray-bin
sudo systemctl enable --now v2raya
sudo systemctl status v2raya
```

### Ubuntu (official apt repo)
```bash
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://apt.v2raya.org/key/public-key.asc | sudo tee /etc/apt/keyrings/v2raya.asc >/dev/null
echo "deb [signed-by=/etc/apt/keyrings/v2raya.asc] https://apt.v2raya.org/ v2raya main" | sudo tee /etc/apt/sources.list.d/v2raya.list
sudo apt update
sudo apt install -y v2raya xray
sudo systemctl enable --now v2raya
sudo systemctl status v2raya
```

### Fedora (COPR)
```bash
sudo dnf -y copr enable zhullyb/v2rayA
sudo dnf -y install v2raya v2ray
sudo systemctl enable --now v2raya
sudo systemctl status v2raya
```

### Web UI
- Открой `http://127.0.0.1:2017`
- Дальше все операции можно делать через UI без CLI-команд.

## 2) Импорт ключей Outline
- В `v2rayA` используй import node/link и вставляй access key из Outline.
- Ключ Outline обычно имеет вид `ss://...` (Shadowsocks URI).
- После импорта выбери ноду и нажми Connect.

## 3) UI-база (System Proxy + TUN + RoutingA)
Рекомендуемая база в UI:
1. `System Proxy`: ON
2. `Transparent Proxy`: `TUN` (в некоторых сборках может называться `tun2`)
3. `Rule Port Distribution`: `RoutingA`
4. Default route/policy: `proxy`

## 4) RoutingA: готовый шаблон
```txt
# --- Local bypass (must-have for TUN) ---
domain(domain:localhost)->direct
domain(suffix:local)->direct
ip(geoip:private)->direct

# --- Dev / Work (force proxy) ---
domain(domain:github.com)->proxy
domain(suffix:githubusercontent.com)->proxy
domain(domain:gitlab.com)->proxy
domain(domain:bitbucket.org)->proxy
domain(domain:docker.com)->proxy
domain(suffix:docker.io)->proxy
domain(domain:hub.docker.com)->proxy
domain(domain:npmjs.com)->proxy
domain(domain:registry.npmjs.org)->proxy
domain(domain:pypi.org)->proxy
domain(domain:files.pythonhosted.org)->proxy

# --- AI / Media ---
domain(domain:chat.openai.com)->proxy
domain(domain:openai.com)->proxy
domain(domain:youtube.com)->proxy
domain(domain:googlevideo.com)->proxy
domain(domain:discord.com)->proxy
domain(domain:cdn.discordapp.com)->proxy

# --- Optional (если используешь) ---
domain(domain:signal.org)->proxy
domain(domain:matrix.org)->proxy
domain(domain:reddit.com)->proxy
domain(domain:x.com)->proxy
domain(domain:twitter.com)->proxy
```

## 5) DNS через DoH (анти-DNS-подмена)
В UI включи anti-DNS-pollution режим и добавь DoH DNS (пример):
```txt
https://dns.google/dns-query
https://cloudflare-dns.com/dns-query
https://dns.quad9.net/dns-query
```

Практика:
1. DoH-серверы лучше пускать через `proxy`, чтобы исключить локальную DNS-подмену.
2. Если используешь отдельный локальный DNS-клиент (например, sing-box/adguard) и уже защищаешь DNS там, проверь, не конфликтует ли это с настройками DNS в `v2rayA`.

## 6) Минимальная проверка
```bash
systemctl status v2raya --no-pager
curl -I https://github.com
curl -I https://openai.com
```

Если сервис не поднялся:
```bash
journalctl -u v2raya -n 100 --no-pager
```
