# Considerações Técnicas

## Arquitetura e Infraestrutura

### Ambientes
| Ambiente    | URL Frontend              | URL API                     | Banco de Dados       |
|-------------|---------------------------|-----------------------------|----------------------|
| Development | `geo.mytrader.local`      | `api.geo.mytrader.local`    | User: `mytrader-d`<br>DB: `mytrader` |
| Staging     | `staging.geo.mytrader.net`| `api.staging.geo.mytrader.net` | User: `mytrader-s`<br>DB: `mytrader` |
| Production  | `geo.mytrader.net`        | `api.geo.mytrader.net`      | User: `mytrader-p`<br>DB: `mytrader` |

### Stack Tecnológico
- **Frontend**: Vue.js
- **Backend**: .NET
- **Banco de Dados**: PostgreSQL
- **Orquestração**: Docker Swarm (staging/prod)
- **Proxy Reverso**: Traefik

### Princípios Arquiteturais
- **DDD** (Domain-Driven Design)
- **SOLID**
- **Persistência**: Armazenamento dedicado em PostgreSQL

### Infraestrutura em Produção
```docker
# Exemplo de configuração Docker Swarm + Traefik (simplificado)
version: '3.8'

services:
  traefik:
    image: traefik:v2.5
    command:
      - "--providers.docker.swarmMode=true"
      - "--entrypoints.web.address=:80"
    ports:
      - "80:80"
    deploy:
      mode: global
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock

  frontend:
    image: mytrader-geo-frontend:prod
    deploy:
      replicas: 3
    labels:
      - "traefik.http.routers.frontend.rule=Host(`geo.mytrader.net`)"

  backend:
    image: mytrader-geo-backend:prod
    environment:
      - DB_USER=mytraderp
      - DB_NAME=mytrader
    deploy:
      replicas: 2
    labels:
      - "traefik.http.routers.api.rule=Host(`api.geo.mytrader.net`)"