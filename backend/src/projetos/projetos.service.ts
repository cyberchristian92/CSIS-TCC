import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AuditoriaService } from '../auditoria/auditoria.service';
import { CreateProjetoDto } from './dto/create-projeto.dto';
import { UpdateProjetoDto } from './dto/update-projeto.dto';

@Injectable()
export class ProjetosService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditoriaService: AuditoriaService,
  ) {}

  async criar(areaId: string, dto: CreateProjetoDto, userId: string) {
    const projeto = await this.prisma.projeto.create({
      data: {
        area_id: areaId,
        nome: dto.nome,
        descricao: dto.descricao,
        prazo: dto.prazo ? new Date(dto.prazo) : undefined,
      },
    });
    await this.auditoriaService.registrar(userId, 'CRIAR', 'Projeto', projeto.id, null, projeto);
    return projeto;
  }

  listarPorArea(areaId: string) {
    return this.prisma.projeto.findMany({ where: { area_id: areaId }, orderBy: { nome: 'asc' } });
  }

  async buscar(id: string) {
    const projeto = await this.prisma.projeto.findUnique({
      where: { id },
      include: { missoes: true, documentos: true, arquivos: true },
    });
    if (!projeto) {
      throw new NotFoundException('Projeto não encontrado.');
    }
    return projeto;
  }

  async atualizar(id: string, dto: UpdateProjetoDto, userId: string) {
    const anterior = await this.buscar(id);
    const atualizado = await this.prisma.projeto.update({
      where: { id },
      data: {
        nome: dto.nome,
        descricao: dto.descricao,
        status: dto.status,
        prazo: dto.prazo ? new Date(dto.prazo) : undefined,
      },
    });
    await this.auditoriaService.registrar(userId, 'ATUALIZAR', 'Projeto', id, anterior, atualizado);
    return atualizado;
  }

  async remover(id: string, userId: string) {
    const anterior = await this.buscar(id);
    await this.prisma.projeto.delete({ where: { id } });
    await this.auditoriaService.registrar(userId, 'REMOVER', 'Projeto', id, anterior, null);
    return { ok: true };
  }
}
