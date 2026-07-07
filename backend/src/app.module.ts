import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './auth/auth.module';
import { ProjetosModule } from './projetos/projetos.module';
import { MissoesModule } from './missoes/missoes.module';
import { ArquivosModule } from './arquivos/arquivos.module';
import { EntregasModule } from './entregas/entregas.module';
import { RevisoesModule } from './revisoes/revisoes.module';
import { AuditoriaModule } from './auditoria/auditoria.module';

@Module({
  imports: [AuthModule, ProjetosModule, MissoesModule, ArquivosModule, EntregasModule, RevisoesModule, AuditoriaModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
