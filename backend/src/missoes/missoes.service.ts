import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AuditoriaService } from '../auditoria/auditoria.service';
import { CreateMissaoDto } from './dto/create-missao.dto';
import { UpdateMissaoDto } from './dto/update-missao.dto';

@Injectable()
export class MissoesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditoriaService: AuditoriaService,
  ) {}

  async criar(projetoId: string, dto: CreateMissaoDto, userId: string) {
    const missao = await this.prisma.missao.create({
      data: {
        projeto_id: projetoId,
        titulo: dto.titulo,
        descricao: dto.descricao,
        criterio_aceite: dto.criterio_aceite,
        valor_bounty: dto.valor_bounty,
        prazo: dto.prazo ? new Date(dto.prazo) : undefined,
      },
    });
    await this.auditoriaService.registrar(userId, 'CRIAR', 'Missao', missao.id, null, missao);
    return missao;
  }

  listarPorProjeto(projetoId: string) {
    return this.prisma.missao.findMany({ where: { projeto_id: projetoId }, orderBy: { titulo: 'asc' } });
  }

  listarPorResponsavel(userId: string) {
    return this.prisma.missao.findMany({
      where: { responsavel_id: userId },
      orderBy: { prazo: 'asc' },
      include: { projeto: { select: { id: true, nome: true } } },
    });
  }

  async buscar(id: string) {
    const missao = await this.prisma.missao.findUnique({
      where: { id },
      include: { entregas: true, responsavel: { select: { id: true, nome: true, email: true } } },
    });
    if (!missao) {
      throw new NotFoundException('Missão não encontrada.');
    }
    return missao;
  }

  async atualizar(id: string, dto: UpdateMissaoDto, userId: string) {
    const anterior = await this.buscar(id);
    const atualizado = await this.prisma.missao.update({
      where: { id },
      data: {
        titulo: dto.titulo,
        descricao: dto.descricao,
        criterio_aceite: dto.criterio_aceite,
        valor_bounty: dto.valor_bounty,
        prazo: dto.prazo ? new Date(dto.prazo) : undefined,
      },
    });
    await this.auditoriaService.registrar(userId, 'ATUALIZAR', 'Missao', id, anterior, atualizado);
    return atualizado;
  }

  async atribuir(id: string, responsavelId: string, userId: string) {
    const anterior = await this.buscar(id);
    const atualizado = await this.prisma.missao.update({
      where: { id },
      data: { responsavel_id: responsavelId },
    });
    await this.auditoriaService.registrar(userId, 'ATRIBUIR', 'Missao', id, anterior, atualizado);
    return atualizado;
  }

  async iniciar(id: string, userId: string, papel: string) {
    const missao = await this.buscar(id);
    const podeGerenciarTudo = papel === 'ADMIN' || papel === 'LIDER' || papel === 'REVISOR';

    if (missao.responsavel_id !== userId && !podeGerenciarTudo) {
      throw new ForbiddenException('Somente o especialista responsável (ou coordenação/revisão) pode iniciar esta missão.');
    }

    const atualizado = await this.prisma.missao.update({
      where: { id },
      data: { status: 'EM_ANDAMENTO' },
    });
    await this.auditoriaService.registrar(userId, 'INICIAR', 'Missao', id, missao, atualizado);
    return atualizado;
  }

  async atualizarTags(id: string, tags: string[], userId: string) {
    const anterior = await this.buscar(id);
    const atualizado = await this.prisma.missao.update({ where: { id }, data: { tags } });
    await this.auditoriaService.registrar(userId, 'ATUALIZAR_TAGS', 'Missao', id, anterior.tags, tags);
    return atualizado;
  }

  async remover(id: string, userId: string) {
    const anterior = await this.buscar(id);
    await this.prisma.missao.delete({ where: { id } });
    await this.auditoriaService.registrar(userId, 'REMOVER', 'Missao', id, anterior, null);
    return { ok: true };
  }
}
