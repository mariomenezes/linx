# linx
Desafio Linx

### Respostas para o desafio estão em um pdf aqui no github

### Preparando o ambiente:
   
```
# apt update
# apt install git -y
$ git clone http://github.com/mariomenezes/linx.git
```
### Instalando dependências e configurando ambiente referente a parte 2 do desafio:
```
$ cd linx
$ ./install.sh
```
### Executando processos node, executando teste de throughput, adicionando envio de relatórios via contrab e mostrando o relatório atual
```
$ ./run.sh
```
### Softwares utilizados:

- nginx web server e proxy reverso (atende http e https)
- node
- pm2 (uma instäncia por thread, load-balance, auto-restart caso falhe e deploy/rollback via github - total controle de versões)
- wrk (load test tool do serviço nginx)
  
O processo de instalação dos softwares e suas dependências serão feitos de forma automática, no entanto é necessário prestar atenção em possíveis avisos e lembretes de senha no próprio terminal.
