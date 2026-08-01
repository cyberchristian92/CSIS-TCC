import { ConflictException, ForbiddenException, Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../prisma/prisma.service';
import { AuditoriaService } from '../auditoria/auditoria.service';
import { Papel } from '../common/constants/papeis';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';

const SALT_ROUNDS = 10;

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly auditoriaService: AuditoriaService,
  ) {}

  async register(dto: RegisterDto, solicitanteId: string, solicitantePapel: Papel) {
    const existente = await this.prisma.user.findUnique({ where: { email: dto.email } });
    if (existente) {
      throw new ConflictException('Já existe um usuário com este e-mail.');
    }

    if (dto.papelGlobal === 'ADMIN' && solicitantePapel !== 'ADMIN') {
      throw new ForbiddenException('Somente um Admin pode criar outra conta Admin.');
    }

    const senha_hash = await bcrypt.hash(dto.senha, SALT_ROUNDS);
    const user = await this.prisma.user.create({
      data: { nome: dto.nome, email: dto.email, senha_hash, papel_global: dto.papelGlobal ?? 'COLABORADOR' },
    });

    await this.auditoriaService.registrar(solicitanteId, 'CONVIDAR', 'User', user.id, null, {
      nome: user.nome,
      email: user.email,
      papel_global: user.papel_global,
    });

    return this.paraPublico(user);
  }

  async atualizarPapel(id: string, novoPapel: Papel, solicitanteId: string, solicitantePapel: Papel) {
    if (id === solicitanteId) {
      throw new ForbiddenException('Você não pode alterar o próprio papel — peça para outro Admin/Coordenador fazer isso.');
    }
    if (novoPapel === 'ADMIN' && solicitantePapel !== 'ADMIN') {
      throw new ForbiddenException('Somente um Admin pode promover alguém a Admin.');
    }

    const anterior = await this.prisma.user.findUniqueOrThrow({ where: { id } });
    const atualizado = await this.prisma.user.update({ where: { id }, data: { papel_global: novoPapel } });

    await this.auditoriaService.registrar(solicitanteId, 'ALTERAR_PAPEL', 'User', id, { papel_global: anterior.papel_global }, { papel_global: novoPapel });

    return this.paraPublico(atualizado);
  }

  async validarCredenciais(email: string, senha: string) {
    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user) {
      throw new UnauthorizedException('Credenciais inválidas.');
    }

    const senhaValida = await bcrypt.compare(senha, user.senha_hash);
    if (!senhaValida) {
      throw new UnauthorizedException('Credenciais inválidas.');
    }

    return user;
  }

  async login(dto: LoginDto) {
    const user = await this.validarCredenciais(dto.email, dto.senha);

    const token = await this.jwtService.signAsync({
      sub: user.id,
      email: user.email,
      papel: user.papel_global,
    });

    return { token, user: this.paraPublico(user) };
  }

  async me(userId: string) {
    const user = await this.prisma.user.findUniqueOrThrow({ where: { id: userId } });
    return this.paraPublico(user);
  }

  async listarUsuarios() {
    const users = await this.prisma.user.findMany({ orderBy: { nome: 'asc' } });
    return users.map((user) => this.paraPublico(user));
  }

  private paraPublico(user: { id: string; nome: string; email: string; papel_global: string; criado_em: Date }) {
    return {
      id: user.id,
      nome: user.nome,
      email: user.email,
      papel_global: user.papel_global,
      criado_em: user.criado_em,
    };
  }
}
