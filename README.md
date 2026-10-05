# Homelab platform

Локальный Kubernetes-стенд, который поднимается из кода одной командой:
4 виртуальные машины (Vagrant + VirtualBox), настройка через Ansible, кластер k3s.
Тестовый стенд

## Запуск

- `./scripts/up.sh` с нуля создаёт ВМ, настраивает их и собирает кластер k3s (1 bastion, 1 master + 2 worker)
- `./scripts/destroy.sh` полностью удаляет стенд

## Архитектура

```
Windows 11 (VirtualBox + Vagrant)
│
└── host-only сеть 192.168.10.0/24 (интерфейс eth1)
    │
    ├── bastion  192.168.10.10   Ansible, kubectl, helm
    │                            (управляющий узел)
    │
    ├── master   192.168.10.100  k3s server (control plane)
    │
    ├── worker1  192.168.10.111  k3s agent
    └── worker2  192.168.10.112  k3s agent
```

Интерфейс `eth0` (NAT, `10.0.2.15`) одинаков на всех ВМ и нужен только для выхода в интернет.
k3s привязан к `eth1` параметрами `node-ip` и `flannel-iface`.

## Узлы

| ВМ      | IP             | vCPU | RAM, МБ | Роль                     |
|---------|----------------|------|---------|--------------------------|
| bastion | 192.168.10.10  | 1    | 2048    | Ansible, kubectl, helm   |
| master  | 192.168.10.100 | 1    | 2048    | k3s server               |
| worker1 | 192.168.10.111 | 1    | 2048    | k3s agent                |
| worker2 | 192.168.10.112 | 1    | 2048    | k3s agent                |

## Требования

- Windows 11, 16 RAM, 8 CPU
- VirtualBox 7.x, Vagrant (Windows-версия)
- WSL2 с Ubuntu (скрипты запускаются оттуда через `vagrant.exe`)
- Репозиторий лежит на диске Windows (`/mnt/c/...`), иначе `vagrant.exe` не работает

## Быстрый старт

```bash
# 1. Один раз: сгенерировать SSH-ключ для Ansible (не попадает в git)
mkdir -p keys
ssh-keygen -t ed25519 -f keys/ansible_ed25519 -N "" -C ansible

# 2. Поднять стенд
./scripts/up.sh

# 3. Проверить
vagrant.exe ssh bastion -c "kubectl get nodes -o wide"

# Удалить всё
./scripts/destroy.sh
```

## Структура репозитория

```
.
├── Vagrantfile              # описание 4 ВМ
├── Makefile                 # команды на bastion: provision, check, lint, status
├── scripts/                 # up.sh, destroy.sh (запуск из WSL)
├── ansible/
│   ├── ansible.cfg
│   ├── site.yml             # главный плейбук
│   ├── inventory/hosts.yml
│   ├── group_vars/all.yml   # версия k3s, интерфейс flannel
│   └── roles/
│       ├── common/          # swap, модули ядра, sysctl, SSH hardening
│       ├── k3s_server/
│       ├── k3s_agent/
│       └── kubectl_client/  # kubectl, helm, kubeconfig на bastion
└── docs/adr/                # архитектурные решения
```

## Что делает автоматизация

| Роль            | Действия                                                                  |
|-----------------|---------------------------------------------------------------------------|
| `common`        | пакеты, таймзона, отключение swap, модули ядра, sysctl, SSH только по ключам |
| `k3s_server`    | установка k3s закреплённой версии, конфиг с `node-ip` и `flannel-iface`   |
| `k3s_agent`     | получение токена с master, присоединение к кластеру                       |
| `kubectl_client`| kubectl и helm, kubeconfig для пользователя на bastion                    |

## Команды на bastion

```bash
make provision   # применить плейбук
make check       # сухой прогон с diff
make lint        # yamllint + ansible-lint
make status      # узлы и поды
```

## Известные компромиссы

- `host_key_checking = False` в Ansible: после каждого `destroy` ключи ВМ меняются. Для лаборатории допустимо, для продакшена нет.
- Установка k3s не обновляет версию на уже работающем узле (`creates:`). Апгрейд пока делается пересозданием стенда.
- Фаервол (ufw) на узлах не включён, это запланировано на этап безопасности.

## Дорожная карта

- [x] Этап 1. Инфраструктура: Vagrant, Ansible, k3s
- [ ] Этап 2. Приложение, Dockerfile, CI в GitHub Actions
- [ ] Этап 3. Helm, ArgoCD (GitOps), ingress, TLS
- [ ] Этап 4. Prometheus, Grafana, Loki, алерты
- [ ] Этап 5. Секреты, Kyverno, NetworkPolicy
- [ ] Этап 6. Бэкапы, скрипты автоматизации, разбор отказов