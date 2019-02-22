# Libraries
include("./ElasticNetVAR/ElasticNetVAR.jl");
using Main.ElasticNetVAR;
using Random;
using DataFrames;
using FileIO;

# Data
Y=DataFrame(load("./data/data.csv")) |> JArray{Float64,2};
Y=standardize(Y);
Y=Y[:,1:3]' |> JArray{Float64,2};

# Hyperparameters
p=3;
λ=2;
α=1.0;
β=10.0;

# Run
B̂, R̂, Ĉ, V̂, 𝔛0̂, P0̂, Ψ̂_init, Σ̂_init = ecm(Y, p, λ, α, β);
