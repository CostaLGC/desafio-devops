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





### Introdução

O primeiro passo paara o desenvolvimento desta aplicação foi aplicar um manifesto Terraform para provisionar um ambiente de testes na AWS. Este manifesto não faz parte deste documento. 

A ordem de apresentação deste documento segue conforme o projeto foi desenvolvido

- Ubuntu teste
- Mysql com banco NodeDB
- Nodejs App e Nginx Proxy
- Anexo


Os arquivos acrescentados ao projeto estão destacados


├── docker-compose.yaml
├── mysql
│   ├── init.sql
│   ├── mysql.yaml  
│   └── Dockerfile   
├── nginx
│   └── nginx.yaml  
├── node
│   ├── Dockerfile   
│   ├── connectionDb.js
│   ├── index.js
│   ├── node.yaml   
│   ├── package.json
│   └── routes.js
└── ubuntu.yaml


## Ubuntu teste

Foi reaizado o deployment de um pod ubuntu para validar cada camada desta aplicação. Manifesto do deployment no anexo `ubuntu.yaml`
 
  
