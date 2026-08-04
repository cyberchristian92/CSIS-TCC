import 'dotenv/config';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const SALT_ROUNDS = 10;

/// Cria um usuário ADMIN padrão (e um workspace de exemplo) na primeira vez
/// que o banco é migrado — sem isso, um banco novo fica sem nenhum usuário e
/// não tem como logar (o cadastro é fechado: só ADMIN/LIDER podem convidar
/// alguém). Idempotente: não faz nada se já existir qualquer usuário, então
/// rodar de novo num banco que já tem dados reais é seguro.
async function main() {
  const prisma = new PrismaClient({ adapter: new PrismaPg({ connectionString: process.env.DATABASE_URL }) });

  try {
    const totalUsuarios = await prisma.user.count();
    if (totalUsuarios > 0) {
      console.log(`[seed] Banco já tem ${totalUsuarios} usuário(s) — nada a fazer.`);
      return;
    }

    const nome = process.env.SEED_ADMIN_NOME ?? 'Administrador';
    const email = process.env.SEED_ADMIN_EMAIL ?? 'admin@csis.local';
    const senha = process.env.SEED_ADMIN_SENHA ?? 'TrocarSenha123';

    const senha_hash = await bcrypt.hash(senha, SALT_ROUNDS);
    const admin = await prisma.user.create({
      data: { nome, email, senha_hash, papel_global: 'ADMIN' },
    });
    console.log(`[seed] Usuário ADMIN criado: ${email} — troque a senha padrão depois do primeiro login.`);

    await prisma.workspace.create({
      data: {
        nome: 'Workspace de Exemplo',
        descricao: 'Criado automaticamente no primeiro boot — pode apagar quando quiser.',
        areas: {
          create: {
            nome: 'Perícia',
            tipo: 'PERICIA',
            projetos: {
              create: {
                nome: 'Projeto de Exemplo',
                descricao: 'Projeto de demonstração criado pelo seed inicial.',
                status: 'ATIVO',
                missoes: {
                  create: {
                    titulo: 'Missão de exemplo',
                    descricao: 'Edite ou apague — isso é só pra você não abrir o app numa tela vazia.',
                    status: 'PENDENTE',
                    responsavel_id: admin.id,
                  },
                },
              },
            },
          },
        },
      },
    });
    console.log('[seed] Workspace de exemplo criado.');
  } finally {
    await prisma.$disconnect();
  }
}

main().catch((err) => {
  console.error('[seed] Falhou:', err);
  process.exit(1);
});
