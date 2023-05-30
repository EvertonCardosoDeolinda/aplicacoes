# Template para stack de aplicações Java

Repositório template para aplicações Java SpringBoot. Utilizar nos servidores de aplicações de integração Java SpringBoot.

## A estrutura

```
.                           #diretorio base para o stack docker-compose
├── app1                    #diretorio base para o servico 1
│   ├── jarFile             #diretorio que deve conter o .jar para o servico 1
│   └── scripts             #comtem script de entrypoint para o container java
├── app2                    #diretorio base para o servico jar 2 **se houver**
│   ├── jarFile             #diretorio que deve conter o .jar para o servico 2
│   └── scripts             #comtem script de entrypoint para o container java
└── logs                    #agrupa logs de todos os .jar em execução no stack
├── docker-compose.yaml     #arquivo com as definições de deploy via docker-compose
├── .env                    #arquivo com as variaveis de ambiente que definem o deploy
```

## Utilizando o template

Deve-se clonar este repositório GIT para um dedicado à nova aplicação, ou criar um novo partindo deste que é um template no git. No novo repositório, realizar as adequaçoes pré deploy.

### Adequações pre deploy


1. Renomear a pasta **app1** para o nome do novo serviço de integração obedecendo as recomendações do arquivo _app1/jarFile/README.md_ .

2. No arquivo _docker-compose.yaml_, ajustar o nome do service e das variaveis _SERVICE${N}_ de acordo a stack a ser feito o deploy.

Exemplo:

```
.
├── clientes
│   ├── jarFile
│   └── scripts
├── ofertas
│   ├── jarFile
│   └── scripts
└── logs
```

Para a estrutura ilustrada acima, com 2 serviços (**clientes** e **ofertas**), o _docker-compose.yaml_ ficaria da seguinte forma.

```yaml
version: "2.4"
services:
  clientes:
    build: ${SERVICE1}
    restart: unless-stopped
    ports:
      - ${SERVICE1_PORT}:${SERVICE1_PORT}
    environment:
      - JAR_PROFILE=${SERVICE1_PROFILE}
      - JAVA_MAX_MEM=${SERVICE1_MEM}
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro
      - ./logs:/logs:rw
    healthcheck:
      test: curl --fail http://localhost:${SERVICE1_PORT}${SERVICE1_HEALTH_URI} || pkill sleep || exit 1
      interval: 2m
      timeout: 10s
      retries: 35
      start_period: 2m
    command:
      - /scripts/start_java.sh
  ofertas:
    build: ${SERVICE2}
    restart: unless-stopped
    ports:
      - ${SERVICE2_PORT}:${SERVICE2_PORT}
    environment:
      - JAR_PROFILE=${SERVICE2_PROFILE}
      - JAVA_MAX_MEM=${SERVICE2_MEM}
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro
      - ./logs:/logs:rw
    healthcheck:
      test: curl --fail http://localhost:${SERVICE2_PORT}${SERVICE2_HEALTH_URI} || pkill sleep || exit 1
      interval: 2m
      timeout: 10s
      retries: 35
      start_period: 2m
    command:
      - /scripts/start_java.sh
```

No YAML acima foi, foi feito:

- copiado sessão inteira do service 1 (app1 no template) para um nova ficando com duas sessões (app1 e app2)
- depois foram adequados os nomes dos serviços para **clientes** e **ofertas**
- na sessão do segundo serviço, foi alterado todas as variaveis que possuem _SERVICE1_ no nome para _SERVICE2_

3. Definir no arquivo _.env_ as variaveis para cada serviço. Para o exemplo da estrutura acima teriamos variaveis para 2 servicos no arquivo _.env_

```
COMPOSE_PROJECT_NAME=appclube       #diretorio base para o stack

SERVICE1=clientes                   #servico 1 do stack, mesmo nome do dir base para o servico1                     
SERVICE1_PORT=8060                  #porta TCP usada pelo servico 1
SERVICE1_MEM=1024                   #memória maxima para o JAVA do servico 1
SERVICE1_PROFILE=prd                #profile do java pring boot
SERVICE1_HEALTH_URI=/v2/api-docs    #URI a ser usada pelo healthcheck, precisa ser válido e acessível sem parametros. URL final vide conpose

SERVICE2=clientes                   #servico 2 do stack, mesmo nome do dir base para o servico2                     
SERVICE2_PORT=18090                 #porta TCP usada pelo servico 2
SERVICE2_MEM=1536                   #memória maxima para o JAVA do servico 2
SERVICE2_PROFILE=prd                #profile do java pring boot
SERVICE2_HEALTH_URI=/v2/api-docs    #URI a ser usada pelo healthcheck, precisa ser válido e acessível sem parametros. URL final vide conpose
```
4. prontos os arquivos que definem a estrutura do deploy, copiar a pasta **app1** para **app2**, e renomear ambas de acordo (app1 para clientes, app2 para ofertas)

5. copiar para as respectivas pastas os arquivos _.jar_ de cada serviço de aplicação. Exemplo da estrutura de arquivos já com os _.jar_ 

```
.
├── clientes
│   ├── Dockerfile
│   ├── jarFile
│   │   └── clientes.jar
├── ofertas
│   ├── Dockerfile
│   ├── jarFile
│   │   └── ofertas.jar
```

## Deploy em um Docker Host

### Desploy automatico via CI/CD

Esse template ja possui o arquivo necessário para que o deploy desse novo grupo de aplicações seja configurado posteriormente com esteira CI/CD.

Assim como nos grupos de aplicações ja em atividade e providos com esse template, faz-se necessário configurar e ativar a esteira.

#### Configuração CI/CD file

O arquivo com as definições de CI/CD é _.drone.yml_ . Neste, passamos as definições do que o software de esteira [drone.io](https://drone.io) fará em cada evento de **push** com alterações no repositório.

O arquivo ainda no formato do template, tem as inforções abaixo.

```
kind: pipeline
name: default
type: docker

steps:
- name: sync-build-deploy
  image: drillster/drone-rsync
  settings:
    hosts: [ "SERVIDOR-DOCKER.angeloni.com.br" ]
    user: root
    key:
      from_secret: NOME_CHAVE_SSH_PRIV_KEY
    source: ./
    target: /u/docker/integration-apps/NOME_COMPOSE_PROJECT
    exclude: [ "logs", ".git" ]
    delete: true
    script:
      - export PROJECT=NOME_COMPOSE_PROJECT
      - cd /u/docker/integration-apps/
      - chmod -R 770 $PROJECT
      - chmod 775 $PROJECT
      - chmod -R 775 $PROJECT/logs
      - cd $PROJECT
      - unset PROJECT
      - docker-compose up -d --build
    when:
      branch:
        - main
```

Para adequa-lo no repositório clonado e atender os deploys da nova aplicação, é necessário trocar os dois locais que contem **NOME_COMPOSE_PROJECT**. Além disso, deve-se garantir que o path na opção ```target:``` é válido para que a pasta com o **NOME_COMPOSE_PROJECT** seja criada normalmente pela esteira.

#### A chave SSH

Para o funcionamento automático e totalmente livre de interação, o software resposável pela esteira precisa conectar via SSH no host docker a ser feito o deploy. Para isso, uma chave RSA deve ser criada e o conteúdo da **PRIVATE_KEY** cadastrado no vault do [drone-gitea](drone-gitea.angeloni.com.br) .

Para criar a chave, executar em um host Linux:

!!! note
    Recomendado executar a geração de chaves no server docker a ser usado e dentro do $HOME do usuário a ser usado no CI/CD.

```
cd ~/.ssh
ssh-keygen -f drone
```

A chave não deve possuir contra senha.

Uma vez gerada, cadastrar o conteúdo da **PRIVATE_KEY** no drone. Para isso.

1. logar com usuário administrativo do repositório na console web [gitea](gitea.angeloni.com.br)
2. Acessar a [web ui do Drone](https://drone-gitea.angeloni.com.br) no mesmo navegador que está aberto o gitea. O drone se autentica automaticamente com o cookie de sessão do gitea.
3. no painel web do **drone**, clicar em SYNC no canto superior direito para atualizar a lista de repositórios no GIT
4. acessar o repositório que a esteira deve ser configurada
5. acessar Settings e clicar em "Activate Repository"
6. Marcar as opções **Disable Pull Requests** e **Disable forks** na principal tela de config **General**
7. No painel esquerdo, clicar em **Secrets** e criar uma nova. Atribuir o nome exatamente igual ao definido na opção ```from_secret:``` do arquivo _.drone.yml_ do novo repositório.
8. Colar o conteúdo da **PRIVATE_KEY** gerada antes. Obs.: a private key é o arquivo sem extensão _.pub_ no nome.

#### Disparando o deploy inicial via drone.io

Uma vez que todos os arquivos ja foram preparados no novo repositório, incluindo o de CI/CD _.drone.yml_ é necessário via [web ui do Drone](https://drone-gitea.angeloni.com.br) disparar o primeiro build para que depois disso, tudo fique pronto para ocorrer automaticamente.

!!! note

    Neste passo de primeiro build manual do drone.io, ele de fato vai executar a esteira conforme parametrizado no _.drone.yml_. Sendo assim, faça uma checagem adicional se tudo está devidamente configurado.

Acessar o repositório no [web ui do Drone](https://drone-gitea.angeloni.com.br) e em **Builds**, clicar em **New Buid**.

No popup que abre, informar o nome da branch que por padrão é **main** .

Agora basta acompanhar a esteira clicando nela na lista de **executions**.

Se tudo foi configurado adequadamente, os proximos **push** no repositório vão disparar novas execuções da estreira.


### Deploy manual
A estrutura inteira do repositório GIT, agora todo modificado e preparado para atender o deploy das aplicaçoes, deve ser copiado para o local adequado no server desejado. Para estas integrações java, temos usado o diretório base _/u/docker/integration-apps/${COMPOSE_PROJECT_NAME}_. Uma vez no server, iniciar o stack de aplicações.

#### Inicio

!!! Note
  Todos os passos a seguir assumem uma estrutura do exemplo acima... com COMPOSE_PROJECT_NAME **appclube** e dois serviços, **clientes** e **ofertas** . Atentar e adequar sempre os comandos abaixo para a realidade do atual deploy.

```
cd /u/docker/integration-apps/appclube
docker-compose up -d --build
```
A primeira execução vai fazer o build automático da imagem docker caso ele não seja especificado com a opção _--build_ .

#### Atualização manual com novo **.jar**

Para atualizar um stack de aplicações com novas versões do **.jar** de forma manual, basta fazer o seguinte:

- Copiar o novo **.jar** para o repositorio GIT, substituindo o atual
- Copiar o novo **.jar** também para o server, no local adequado substituindo o atual   
    Obs.: isso será automatico quando entrar em cena a esteira de deploy com DRONE CI ou Gitlab Runner
- fazer build da imagem docker, ao qual vai carregar o novo **.jar**. O comando abaixo também instrui o docker a recriar o container baseado na imagem mais recente.

```
cd /u/docker/integration-apps/appclube
docker-compose up -d --build
```

#### Restart

Cada serviço do stack ja possui ativo um healthcheck e faz o restart automatico do container baseado na disponibilidade da URI definida nas variáveis **SERVICE${N}_HEALTH_URI**. Mas, se necessário for, cada serviço do stack pode ser reiniciado manualmente.

```
cd /u/docker/integration-apps/appclube
docker-compose restart SERVICO
```

Para os exemplos acima, ao qual os serviços são **clientes** e **ofertas** seria:

```
cd /u/docker/integration-apps/appclube
docker-compose restart [ clientes | ofertas ]
```

Para reiniciar todos basta não especificar o serviço:

```
docker-compose restart
```

## Undeploy

Para fazer undeploy, ou seja, parar por completo os serviços e remover os ativos docker:

```
cd /u/docker/integration-apps/appclube
docker-compose down
```
Algumas situações em que isso é necessário:

- mudança no **docker-compose.yaml**
- manutenção no server que afete as aplicações

Uma vez feito o undeploy, as aplicaçoes só sobem novamente com o comando **docker-compose up -d**. Sendo assim, em casos de **down** seguido de restart do server, as aplicações não subirão automatico com o servidor.

Caso o restart ocorra sem um **down**, elas vão iniciar automático.

Esse comportamento é definido no **docker-compose.yaml** com a opção ```restart: unless-stopped``` de cada serviço.