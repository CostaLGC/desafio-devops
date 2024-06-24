# Desafio Devops

O projeto contém uma aplicação básica com Node, Ngnix e MySQL. 

A cada atualização da página, um novo registro será cadastrado no banco de dados e será mostrado na listagem, na mesma página.  

O projeto contém algumas falhas e erros, analise e implemente as devidas correções.

Se não entender algum conceito ou parte do problema, não é motivo para se preocupar! Queremos que faça o desafio até onde souber.

### O que deve ser feito? ### 

 - ajustes que fazem todas as aplicações subirem e se comunicarem
 - clusterize esta aplicação para o Kubernetes, utilize o cluster de sua preferência mas não esqueça de fornecer o(s) manifesto(s) que criar 
 - um README contendo os seus pensamentos ao longo do projeto para identificação e correção dos erros

Faça um fork e realize commits ao longo do processo para que possamos entender o seu modo de pensar! :)



# Solução

##

### Introdução

O primeiro passo para o desenvolvimento desta aplicação foi aplicar um manifesto Terraform para provisionar um ambiente de testes na AWS. Este manifesto não faz parte deste documento. 

A ordem de apresentação deste documento segue conforme o projeto foi desenvolvido

- Ubuntu teste
- Mysql com banco de dados NodeDB
- Nodejs App e Ngnix Proxy
- Validações

Estrutura de diretórios do projeto

├── docker-compose.yaml  
├── mysql  
│   ├── init.sql    
│   ├── mysql.yaml   
│   └── Dockerfile   
├── ngnix   
│   └── ngnix.yaml    
├── node  
│   ├── Dockerfile     
│   ├── connectionDb.js  
│   ├── index.js  
│   ├── node.yaml     
│   ├── package.json  
│   └── routes.js  
└── ubuntu.yaml  


## Ubuntu teste

Foi realizado o deployment de um pod ubuntu para validar cada camada desta aplicação. Manifesto do deployment no anexo `ubuntu.yaml`
 

---

## MySQL

MySQL com NodeDB contendo os seguintes Itens

- Dockerfile
- Secrets
- Persisten Volumes
- PersistentVolumeClaim
- Deployment
- Service

Visando a configuração do banco de dados a imagem selecionada para o deployment do pod foi preconfigurada via dockerfile. Outra opção seria uma configuração de DB via  `configmap` , foi realizada esta configuração, porém sem sucesso - quando adicionado outro volume mount para persistencia do banco de dados, não ocorria a configuração definida no `configmap` - as hipoteses para este comportamento não foram investigadas e optou-se por seguir outra estratégia.

`secrets` para não expor senhas de acesso ao DB, `persistent volume`  e `persistent volume claim` visando a persistencia de dados. `deployment`  e `service` para executar e expor o banco de dados dentro do cluster. 

Todos os arquivos desta etapa, `Dockerfle` e `mysql.yaml` estão em `/desafio-devops/mysql/`. Foi realizada a construção e upload da imagem docker para o repositório DockerHub, em seguida aplicou-se o `mysql.yaml`.


---






---

### NodeJS App e Ngnix Proxy

NodeJS contendo os seguintes itens K8s

- Dockerfile
- Deployment
- Service

Para o desenvolvimento desta etapa foram utilizados os arquivos da aplicação fornecidos juntamente com o `Dockefile` modifica e `node.yaml` no diretório `/desafio-devops/node/`. 

No Dockerfile, foram ajustados alguns comandos como

```yaml
RUN npm install
CMD ["node", "index.js"]
```

Com o Dockerfile pronto, foi realizado o empacotamento da aplicação via `build` e `push` , gerando uma imagem específica no repositório Docker Hub. 

Dando seguimento, foram construidos os manifestos Kubernetes para o NodeJS App, contendo `deployment` e `service` . 

A aplicaçao rodou por alguns segundos e apresentou erro - havia uma diferença na declaração do nome do banco de dados. A seguir está a evidência:

```yaml
Rodando na porta 3000
/node_modules/mysql/lib/protocol/Parser.js:437
      throw err; // Rethrow non-MySQL errors
      ^

Error: ER_NO_SUCH_TABLE: Table 'nodedb.peoples' doesn't exist
    at Query.Sequence._packetToError 
```

Neste momento, voltamos a primeira etapa - construção do banco de dados - e toda a declaração do MySQL foi revisada para corrigir o nome do DB e fazer novo deploy.

DE:       node_bd  
PARA:     nodedb  

---

Após redefinir o nome do DB na construção da imagem docker. Realizamos outro deploy. A seguir, está demonstrada a execução do manifesto Kubernetes NodeJS e análise de logs da aplicação. 

```yaml
root@kubectl:/home/ubuntu/desafio-devops/node# kubectl apply -f node15.yaml
deployment.apps/app-node created
service/nodejs-service created
```

```yaml
root@kubectl:/home/ubuntu/desafio-devops/node# kubectl get deployments
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
app-node   2/2     2            2           31s
mysql      1/1     1            1           10m

root@kubectl:/home/ubuntu/desafio-devops/node# kubectl get services
NAME             TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
db               ClusterIP   172.20.218.185   <none>        3306/TCP   13m
kubernetes       ClusterIP   172.20.0.1       <none>        443/TCP    128m
nodejs-service   ClusterIP   172.20.58.250    <none>        3000/TCP   4m12s

root@kubectl:/home/ubuntu/desafio-devops/node# kubectl get pods
NAME                        READY   STATUS    RESTARTS   AGE
app-node-5f79fdd889-gztqf   1/1     Running   0          45s
app-node-5f79fdd889-mhvwc   1/1     Running   0          45s
mysql-d776f956b-cscgz       1/1     Running   0          10m

root@kubectl:/home/ubuntu/desafio-devops/node# kubectl logs app-node-5f79fdd889-gztqf
Rodando na porta 3000
root@kubectl:/home/ubuntu/desafio-devops/node# kubectl logs app-node-5f79fdd889-mhvwc
Rodando na porta 3000

root@kubectl:/home/ubuntu/desafio-devops/node# kubectl exec -it app-node-5f79fdd889-gztqf -- /bin/bash
root@app-node-5f79fdd889-gztqf:/usr/src/app# apt install curl

root@app-node-5f79fdd889-gztqf:/usr/src/app# curl http://127.0.0.1:3000/
<h1>Desafio Devops!</h1>Enzo Moreira<br>root@app-node-5f79fdd889-gztqf:/usr/src/app#

root@app-node-5f79fdd889-gztqf:/usr/src/app# curl http://nodejs-service:3000/
curl: (7) Failed to connect to nodejs-service port 3000: Connection refused
root@app-node-5f79fdd889-gztqf:/usr/src/app# curl http://172.20.58.250:3000/
curl: (7) Failed to connect to 172.20.58.250 port 3000: Connection refused
```

Como podemos observar na analise - funciona localmente mas não funciona via rede dentro do cluster.

Para a resolução deste problema, optou-se por empacotar a aplicação em outras imagens, sendo elas o node 14 e 16 testadas com o mesmo comportamento. Em seguida uma imagem Alpine foi utilizada para empacotar a aplicação e funcionou. O dockerfile está em `/desafio-devops/node/`.

Por fim, foi realizado o desenvolvimento do manifesto kubernetes p/ Ngnix Proxy

---

### Validação

```yaml
root@ubuntu-deployment-d4597d687-xvwqp:/# curl http://node-app-service:3000/
<h1>Desafio Devops!</h1>Frederico Silva<br>Carlos Silva<br>

root@ubuntu-deployment-d4597d687-xvwqp:/# curl http://ngnix-proxy-service/
<h1>Desafio Devops!</h1>Frederico Silva<br>Carlos Silva<br>César Reis<br>

root@ubuntu-deployment-d4597d687-xvwqp:/# curl http://afa0d3b85788d41b48a51e145c243edc-1599917297.us-east-2.elb.amazonaws.com/
<h1>Desafio Devops!</h1>Frederico Silva<br>Carlos Silva<br>César Reis<br>Enzo Costa<br>root@ubuntu-deployment-d4597d687-xvwqp:/#
```


![Untitled](/nodejs-app-validação.png)

---
