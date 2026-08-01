import { IsString } from 'class-validator';

export class AtribuirMissaoDto {
  @IsString()
  responsavelId: string;
}
