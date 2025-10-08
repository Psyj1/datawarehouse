/*Ambiente de Produção*/

create database if not exists HotelDallasProd;

use HotelDallasProd;

create table clientes
(
id_Cliente int primary key,
nome varchar(100),
idade INT,
pais varchar(50)
);

create table Reservas
(
id_Reserva int primary key,
id_Cliente int,
data_entrada date,
data_saida date,
numero_noites int,
foreign key (id_cliente) references clientes(id_cliente)
);

create table quartos
(
id_quarto int primary key,
tipo_quarto varchar(50),
andar int,
preco_diaria decimal(10,2)
);

create table servicos
(
id_servico int primary key,
nome_servico varchar(100),
categoria varchar(50),
preco decimal(10, 2)
);

create table oucupacoes
(
id_oucupacao int primary key,
id_cliente int,
id_reserva int,
id_quarto int,
data date,
id_servico int,
quantidade int,
valor_total decimaL(10,2),
foreign key (id_cliente)references clientes(id_cliente),
foreign key (id_reserva) references reservas(id_reserva),
foreign key (id_quarto) references quartos(id_quarto),
foreign key (id_servico) references servicos(id_servico)
);

-- Inserindo dados na base producao

insert into clientes(id_cliente, nome, idade, pais) values
(1, 'Carlos Silva', 45, 'Brasil'),
(2, 'Anan Gomez', 34, 'Argentina'),
(3, 'Lucas Andrade', 29, 'Brasil'),
(4, 'Maria Lopez', 40, 'Mexico'),
(5, 'Tomás Perez', 35, 'Chile');

insert into Reservas (id_reserva, id_cliente, data_entrada, data_saida, numero_noites) values
(1,1, '2023-01-10', '2023-01-15',5),
(2,2, '2023-01-12', '2023-01-14',2),
(3,3, '2023-01-05', '2023-01-10',5);

insert into Quartos (id_quarto, tipo_quarto, andar, preco_diaria) values
(1, 'Suite Luxo', 3,500.00),
(2, 'Quarto Standard',2,300.00),
(3, 'Quarto Deluxe', 4,450.00);

insert into Servicos (id_servico, nome_servico, categoria, preco) values
(1, 'Café da manha', 'alimentacao', 30.00),
(2, 'SPA', 'Bem-estar', 120.00),
(3, 'Lavanderia', 'servico', 50.00);

insert into oucupacoes (id_oucupacao, id_cliente, id_reserva, id_quarto, data, id_servico, quantidade,
						valor_total) values
(1,1,1,1,'2023-02-10',1,1,500.00),
(2,2,2,2,'2023-02-12',2,1,300.00),                        
(3,3,3,3,'2023-02-05',3,1,450.00);


-- Criar o ambiente do Data Warehouse(DW)
create database if not exists HotelDallasDW;
use HotelDallasDW;

create table DimClientes
(
id_cliente int primary key,
nome varchar(100),
idade int,
pais_origem varchar(50)
);

create table DimReservas
(
id_reserva int auto_increment primary key,
data_entrada date,
data_saida date,
numero_noites int
);

create table DimQuarto
(
id_quarto int primary key,
tipo_quarto varchar(50),
andar int,
preco_diaria decimal(10, 2)
);

create table DimTempo
(
id_tempo int primary key,
data date,
ano int,
mes int, 
trimestre int,
dia_semana varchar(10)
);

create table DimServico
(
id_servico int primary key,
nome_servico varchar(100),
categoria varchar(50),
preco decimal(10,2)
);

-- Tabela Fato, irá relacionar todas as tabelas
create table fatoOucupacao
(
id_oucupacao int primary key,
id_cliente int,
id_reserva int,
id_quarto int,
id_tempo int,
id_servico int,
quantidade int,
valor_total decimal(10,2),
foreign key(id_cliente) references DimClientes(id_cliente),
foreign key(id_reserva) references DimReservas(id_reserva),
foreign key(id_quarto) references DimQuarto(id_quarto),
foreign key(id_tempo) references DimTempo(id_tempo),
foreign key(id_servico) references DimServico(id_servico)
);

-- Transferência de Dados da Produção para o DW
use hotelDallasprod;

-- Extração da Tabela Clientes para a tabela DimClientes DW
insert into hoteldallasdw.DimClientes(id_cliente, nome, idade, pais_origem)
select id_cliente, nome, idade, pais from hoteldallasprod.Clientes;

select * from dimclientes;

-- Extração da tabela reservas para tabela DimReserva DW
insert into dimreserva (Id_Reserva, Data_Entrada, Data_saida, numero_noites)
select Id_Reserva, Data_Entrada, Data_Saida, Numero_noites from hoteldallasprod.Reservas;

select * from dimreserva;

-- Extração da tabela Quartos para DimQuarto DW( Id_Quarto, Tipo_Quarto, Andar, preço_diaria )
INSERT INTO DimQuarto (ID_Quarto, Tipo_Quarto, Andar, Preco_Diaria)
select ID_Quarto, Tipo_Quarto, Andar, Preco_Diaria from hoteldallasprod.Quartos;

select * from dimQuarto;

-- Populando DimTempo

select * from dimTempo;
Insert into DimTempo (Id_Tempo, Data, Ano, Mes, Trimestre, Dia_Semana)
select
	row_number() over (order by Data) as Id_Tempo,
    Data,
    Year(Data) as Ano,
    Month(Data) as Mes,
    Quarter(Data) as Trimestre,
    dayname(Data) as Dia_Semana
from (select distinct Data from hoteldallasprod.oucupacoes) as T;

select * from dimTempo;

select * from hoteldallasprod.oucupacoes;

-- Extração dos dados da tabela Oucupação para a tabela FatoOucupacao DW
select * from fatooucupacao;

insert into fatooucupacao (Id_Ocupacao, id_cliente, id_reserva, id_quarto, id_tempo, id_servico, quantidade, valor_total)
select
	oucupacoes.id_oucupacao,
    oucupacoes.id_cliente,
    oucupacoes.id_reserva,
    oucupacoes.id_Quarto,
    T.Id_tempo,
    oucupacoes.id_servico,
    oucupacoes.quantidade,
    oucupacoes.Valor_Total
    from hoteldallasprod.oucupacoes
    join dimtempo as T on T.Data=oucupacoes.Data;
    
select * from fatoOucupacao;

-- Exemplo 1: Taxa de Ocupação por Mês
select DimTempo.mes, count(fatooucupacao.id_oucupacao) as Oucupacao
from fatoucupacao
join dimtempo on fatooucupacao.id_tempo=dimtempo.id_tempo;

-- Exemplo 2: Faturamento Total por Tipo de Quarto
select DimQuarto.TipoQuarto, SUM(FatoOucupacao.Valor_Total) as Faturamento_Total from FatoOucupacao join DimQuarto on FatoOucupacao.ID_Quarto = DimQuarto.ID_Quarto 
group by DimQuarto.Tipo_Quarto;

-- Exemplo 3: Serviços mais utilizados pelos hóspedes
select DimServico.Nome_Servico, count(FatoOucupacao.ID_Oucupacao) as Utilizacoes from FatoOucupacao join DimServico on FatoOucupacao.ID_Servico = DimServico.ID_Servico
group by DimServico.Nome_Servico;