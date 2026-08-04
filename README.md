# CSIS — Plataforma de Gestão Pericial

Plataforma web para gestão de equipes de perícia computacional forense: hierarquia de trabalho (Workspace → Área → Projeto → Missão), fluxo de Entregas e Revisões com trava de **Segregação de Funções** (um revisor nunca aprova o próprio trabalho), upload de arquivos com hash SHA-256, documentos em markdown, auditoria automática de tudo que acontece no sistema e exportação de relatórios. Desenvolvido como Trabalho de Conclusão de Curso.

**Stack**: NestJS + Prisma + PostgreSQL (backend) · Flutter Web (frontend) · Docker Compose.

## Início rápido

Pré-requisitos: **[Docker Desktop](https://www.docker.com/products/docker-desktop/)** (backend + banco) e o **[Flutter SDK](https://docs.flutter.dev/get-started/install)** (frontend, versão 3.x — o projeto foi testado com Flutter 3.44).

### 1. Backend + banco de dados (um comando só)

```bash
docker compose up -d --build
```

Isso sobe o PostgreSQL, builda a imagem do backend, aplica todas as migrations do Prisma e cria um **usuário administrador padrão** automaticamente — tudo sozinho, sem precisar instalar Node ou rodar comando nenhum manualmente. Acompanhe com `docker compose logs -f backend` se quiser ver o progresso.

Quando terminar, a API está em `http://localhost:3000`.

**Credenciais do admin criado automaticamente:**
| Campo | Valor padrão |
|---|---|
| E-mail | `admin@csis.local` |
| Senha | `TrocarSenha123` |

> Troque a senha assim que logar pela primeira vez. Para usar credenciais diferentes já na criação, copie `backend/.env.example` para um arquivo `.env` na raiz do projeto (mesmo diretório do `docker-compose.yml`) e ajuste `SEED_ADMIN_EMAIL`/`SEED_ADMIN_SENHA`/`SEED_ADMIN_NOME` antes de rodar o `docker compose up`.

### 2. Frontend

Em outro terminal:

```bash
cd frontend
flutter pub get
flutter run -d chrome --web-port=5000
```

Abre em `http://localhost:5000`. Faça login com as credenciais acima.

---

## Rodando o backend sem Docker (pra quem vai mexer no código dele)

Se você vai desenvolver no backend, rodar direto com `npm` dá hot-reload de verdade (o Docker acima é ótimo pra só *usar* o sistema, não pra editar o código dele em tempo real).

```bash
# 1. Sobe só o banco (o backend roda fora do Docker agora)
docker compose up -d db

# 2. Instala dependências
cd backend
npm install

# 3. Configura o .env
cp .env.example .env
# os valores padrão do .env.example já batem com o docker-compose.yml, não precisa editar nada pra rodar local

# 4. Aplica as migrations e cria o admin padrão
npx prisma migrate deploy
npx prisma db seed

# 5. Roda em modo desenvolvimento (watch/hot-reload)
npm run start:dev
```

## Estrutura do projeto

```
csis-platform/
├── docker-compose.yml    # Postgres + backend (um comando sobe tudo)
├── backend/              # API NestJS + Prisma
│   ├── src/               # um módulo por domínio (auth, missoes, entregas, revisoes, ...)
│   ├── prisma/
│   │   ├── schema.prisma  # modelo de dados
│   │   ├── migrations/    # histórico de migrations (nunca editar manualmente)
│   │   └── seed.ts        # cria o admin padrão + um workspace de exemplo
│   ├── Dockerfile
│   └── .env.example
└── frontend/              # Flutter Web
    └── lib/
        ├── screens/, widgets/   # telas e componentes
        ├── providers/           # estado da aplicação (Provider)
        ├── services/            # cliente HTTP
        └── models/              # modelos de dados espelhando a API
```

## Solução de problemas

**`docker compose up` reclama de porta já em uso (5433 ou 3000)** — outro processo/projeto já está usando essa porta na sua máquina. Pare o que está usando (`netstat -ano | findstr :3000` no Windows, ou `lsof -i :3000` no Mac/Linux) ou troque a porta no `docker-compose.yml` (lado esquerdo do `"host:container"`).

**Erro de `Prisma Client` desatualizado / campo que não existe** — depois de qualquer alteração no `prisma/schema.prisma` rodando fora do Docker, é preciso regenerar o client:
```bash
npx prisma generate
```
Rodando via Docker isso já acontece automaticamente a cada build (`docker compose up -d --build`).

**"Docker Desktop não está rodando"** — abra o aplicativo Docker Desktop antes de rodar `docker compose up` (no Windows/Mac ele precisa estar ativo em segundo plano).

**`flutter: comando não encontrado`** — o Flutter SDK precisa estar instalado e no PATH. Confirme com `flutter doctor`.

**Quero acessar pelo celular** — o app já é responsivo. Descubra o IP local da máquina que está rodando o projeto (`ipconfig` no Windows, `ifconfig`/`ip addr` no Mac/Linux) e acesse `http://SEU_IP:5000` pelo navegador do celular, **na mesma rede Wi-Fi**. Talvez seja necessário adicionar esse IP em `FRONTEND_ORIGIN` no `.env` do backend (ou na variável `FRONTEND_ORIGIN` do `docker-compose.yml`) pra liberar o CORS.

**Quero resetar tudo e começar do zero** — `docker compose down -v` apaga o volume do Postgres (perde todos os dados). Na próxima subida (`docker compose up -d --build`), o seed cria o admin padrão de novo automaticamente.
