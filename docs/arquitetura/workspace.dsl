workspace "DT-Blocks 2.0" "Arquitetura do DT-Blocks 2.0 - Ferramenta web colaborativa em tempo real para Diagramas de Blocos de Confiabilidade (RBD)" {

    !identifiers hierarchical

    configuration {
        scope softwaresystem
    }

    model {
        participante = person "Participantes" "Editores e leitores." "Participante"

        dtblocks = softwareSystem "DT-Blocks 2.0" "Ferramenta web colaborativa para Diagramas de Blocos de Confiabilidade (RBD)." {
            navegador = container "Navegador" "" "React · TypeScript" "Cliente,Aplicacao" {
                compModeloLayout = component "Modelo e layout" "Árvore tipada do diagrama (série, paralelo, k-de-n) e posicionamento automático por layout recursivo." "TypeScript" "Aplicacao"
                compDesenhoSvg = component "Desenho em SVG" "Desenho vetorial próprio do diagrama RBD na tela." "React / SVG" "Aplicacao"
                compInteracao = component "Interação" "Edição de blocos, travas de campo, desfazer individual (até 100 ações) e mensagens WebSocket." "TypeScript / WebSocket" "Aplicacao"
                compExportacao = component "Exportação em SVG e PNG" "Exportação em SVG e PNG feita no navegador (além de JSON e função estrutural)." "TypeScript" "Aplicacao"
            }

            nginx = container "Nginx" "" "Proxy Reverso" "Proxy"

            fastapi = container "Processo FastAPI" "1 worker · Sessões em memória" "Python · FastAPI · Uvicorn · Pydantic" "DecisaoCentral" {
                compLimites = component "Limites de uso" "Limites por IP e por sessão (criação de sessões, tentativas de senha, comandos/s e cálculo a cada 1 s)." "Python" "Aplicacao"
                compSessoesMemoria = component "Sessões em memória" "Estado das sessões em memória (diagrama versionado e participantes), garantindo propagação em 500 ms." "Python (Memória)" "DecisaoCentral"
                compTravas = component "Travas de campo" "Bloqueio por campo com batimento e arrendamento (liberação em até 30 s na desconexão)." "Python" "Aplicacao"
                compCalculo = component "Cálculo de confiabilidade" "Disponibilidade, curva R(t), MTTF, MTBF, falhas por ano, indisponibilidade anual, equações LaTeX e sensibilidade." "Python" "Aplicacao"
                compRepositorio = component "Repositório de sessões" "Interface de repositório que carrega sessões do banco e grava alterações em lote (1 a 2 s)." "Python / SQLAlchemy" "Aplicacao"
                compMetricas = component "Métricas por hora" "Contadores anônimos na aplicação e resumo por hora." "Python" "Aplicacao"
            }

            sqlite = container "SQLite (modo WAL)" "" "Banco Embarcado · Arquivo em Volume" "BancoDados"
        }

        # Relações principais (Nível 1)
        participante -> dtblocks.navegador "Interage" "Interface Web"
        dtblocks.navegador -> dtblocks.nginx "HTTPS / WebSocket" "HTTPS · WSS"
        dtblocks.nginx -> dtblocks.fastapi "HTTP / WS" "HTTP · WebSocket"
        dtblocks.fastapi -> dtblocks.sqlite "Escrita em lote" "SQLAlchemy · WAL"

        # Relações internas do Navegador (Nível 2B)
        participante -> dtblocks.navegador.compInteracao "Manipula blocos, parâmetros, cálculo e desfazer" "Interface Web"
        participante -> dtblocks.navegador.compExportacao "Exporta diagrama (SVG, PNG, JSON, função estrutural)" "Interface Web"
        dtblocks.navegador.compInteracao -> dtblocks.nginx "HTTPS e WebSocket (comandos, travas, cálculo, snapshots e difusões)" "HTTPS / WebSocket"
        dtblocks.navegador.compInteracao -> dtblocks.navegador.compModeloLayout "Atualiza o modelo após confirmação ('aplicado') do servidor" "TypeScript"
        dtblocks.navegador.compModeloLayout -> dtblocks.navegador.compDesenhoSvg "Árvore do RBD e coordenadas do layout recursivo" "TypeScript"
        dtblocks.navegador.compDesenhoSvg -> dtblocks.navegador.compExportacao "SVG da tela para exportação em SVG e PNG" "DOM / SVG"

        # Relações internas do Processo FastAPI (Nível 2A)
        dtblocks.nginx -> dtblocks.fastapi.compLimites "Entrega requisições e mensagens WebSocket" "HTTP / WebSocket"
        dtblocks.fastapi.compLimites -> dtblocks.fastapi.compSessoesMemoria "Comandos e acessos validados pelos limites de uso" "Memória (Python)"
        dtblocks.fastapi.compSessoesMemoria -> dtblocks.fastapi.compTravas "Concede, renova por batimento e expira travas de campo" "Memória (Python)"
        dtblocks.fastapi.compSessoesMemoria -> dtblocks.fastapi.compCalculo "Solicita cálculo de confiabilidade e disponibilidade" "Memória (Python)"
        dtblocks.fastapi.compSessoesMemoria -> dtblocks.fastapi.compRepositorio "Carrega sessão e agenda gravação no banco" "Interface de repositório"
        dtblocks.fastapi.compSessoesMemoria -> dtblocks.fastapi.compMetricas "Atualiza contadores anônimos de uso e desempenho" "Memória (Python)"
        dtblocks.fastapi.compRepositorio -> dtblocks.sqlite "Lê e grava sessões em lote (1–2 s após alteração)" "SQLite (WAL)"
        dtblocks.fastapi.compMetricas -> dtblocks.sqlite "Grava resumo de métricas por hora" "SQLite (WAL)"

        # Ambiente de Implantação (Nível 1: Máquina do Participante, VPS e Fora da VPS)
        producao = deploymentEnvironment "Produção" {
            maquinaPessoa = deploymentNode "Máquina do Participante" "" "Ambiente Cliente" "Fronteira" {
                instNavegador = containerInstance dtblocks.navegador
            }

            vps = deploymentNode "VPS" "" "Linux" "Fronteira" {
                sshVps = infrastructureNode "Serviço SSH" "" "OpenSSH" "Infraestrutura"

                dockerCompose = deploymentNode "Docker Compose" "" "Docker Compose" "Fronteira" {
                    instNginx = containerInstance dtblocks.nginx
                    instFastapi = containerInstance dtblocks.fastapi
                    instSqlite = containerInstance dtblocks.sqlite
                }
            }

            foraVps = deploymentNode "Fora da VPS" "" "Ambiente Externo" "Fronteira" {
                coletorExterno = infrastructureNode "Coletor externo" "" "Python / UNAME Tool" "Externo"
                monitorExterno = infrastructureNode "Monitor externo" "" "Monitoramento Externo" "Externo"
                backupDiario = infrastructureNode "Backup diário" "" "Armazenamento Externo" "Externo"
            }

            # Ligações externas no ambiente de implantação
            foraVps.coletorExterno -> vps.sshVps "SSH (CSV / JSON)" "SSH"
            foraVps.monitorExterno -> vps.dockerCompose.instNginx "HTTPS (disponibilidade)" "HTTPS"
            vps.dockerCompose.instSqlite -> foraVps.backupDiario "Cópia criptografada" "WAL"
        }
    }

    views {
        deployment dtblocks producao "Nivel1_VisaoGeral" {
            title "Nível 1 - Visão Geral da Arquitetura e Implantação (DT-Blocks 2.0)"
            include *
            autoLayout lr
        }

        component dtblocks.fastapi "Nivel2A_DetalheProcessoFastAPI" {
            title "Nível 2A - Detalhe do Processo FastAPI (um worker)"
            include *
            autoLayout lr
        }

        component dtblocks.navegador "Nivel2B_DetalheNavegador" {
            title "Nível 2B - Detalhe do Navegador (React e TypeScript)"
            include *
            autoLayout lr
        }

        dynamic dtblocks.fastapi "Nivel3_FluxoEdicao" "Fluxo de uma edição em tempo real (meta de 500 ms ida e volta)" {
            dtblocks.navegador -> dtblocks.nginx "Editor A pede trava de campo e envia comando de alteração com a versão base"
            dtblocks.nginx -> dtblocks.fastapi.compLimites "Repassa comando pelo WebSocket ao processo único"
            dtblocks.fastapi.compLimites -> dtblocks.fastapi.compSessoesMemoria "Valida limites, permissão, trava, esquema e versão base"
            dtblocks.fastapi.compSessoesMemoria -> dtblocks.fastapi.compTravas "Confere trava de A, aplica alteração em memória e incrementa a versão"
            dtblocks.fastapi.compSessoesMemoria -> dtblocks.fastapi.compRepositorio "Após difundir 'aplicado, nova versão' aos Editores A e B, agenda gravação"
            dtblocks.fastapi.compRepositorio -> dtblocks.sqlite "Grava o diagrama no SQLite em lote (1 a 2 s após a última alteração)"
            autoLayout lr
        }

        styles {
            element "Element" {
                fontSize 22
                shape RoundedBox
            }
            element "DecisaoCentral" {
                background #DCFCE7
                color #14532D
                stroke #16A34A
                strokeWidth 4
                shape RoundedBox
            }
            element "Aplicacao" {
                background #DBEAFE
                color #1E3A8A
                stroke #2563EB
                shape RoundedBox
            }
            element "Proxy" {
                background #E0E7FF
                color #312E81
                stroke #4F46E5
                shape Hexagon
            }
            element "BancoDados" {
                background #FEF3C7
                color #78350F
                stroke #D97706
                shape Cylinder
            }
            element "Externo" {
                background #F1F5F9
                color #1E293B
                stroke #475569
                border Dashed
                shape RoundedBox
            }
            element "Infraestrutura" {
                background #F8FAFC
                color #334155
                stroke #64748B
                shape RoundedBox
            }
            element "Participante" {
                background #DBEAFE
                color #1E3A8A
                stroke #2563EB
                shape Person
            }
        }
    }
}
