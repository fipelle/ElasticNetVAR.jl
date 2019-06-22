__precompile__()

module ElasticNetVAR

	using LinearAlgebra
	using Statistics;
	using Distributions;
	using Distributed;

	const local_path = dirname(@__FILE__);


	# ---------------------------------------------------------------------------------------------------------------------------
	# Types
	# ---------------------------------------------------------------------------------------------------------------------------

	# Aliases (types)
	const FloatVector  = Array{Float64,1};
	const FloatArray   = Array{Float64};
	const JVector{T}   = Array{Union{Missing, T}, 1};
    const JArray{T, N} = Array{Union{Missing, T}, N};

	# Kalman structures

	"""
		KalmanSettings(...)

	Define an immutable structure that includes all the Kalman filter and smoother input.

	# Model
	The state space model used below is,

	``Y_{t} = B*X_{t} + e_{t}``

	``X_{t} = C*X_{t-1} + u_{t}``

	Where ``e_{t} ~ N(0, R)`` and ``u_{t} ~ N(0, V)``.

	# Arguments
	- `Y`: observed measurements (`nxT`)
	- `B`: Measurement equations' coefficients
	- `R`: Covariance matrix of the measurement equations' error terms
	- `C`: Transition equations' coefficients
	- `V`: Covariance matrix of the transition equations' error terms
	- `X0`: Mean vector for the states at time t=0
	- `P0`: Covariance matrix for the states at time t=0
	- `n`: Number of series
	- `T`: Number of observations
	- `m`: Number of latent states
	- `compute_loglik`: Boolean (true for computing the loglikelihood in the Kalman filter)
	- `store_history`: Boolean (true to store the history of the filter and smoother)
	"""
	struct KalmanSettings
		Y::JArray{Float64}
		B::FloatArray
		R::FloatArray
		C::FloatArray
		V::FloatArray
		X0::FloatVector
		P0::FloatArray
		n::Int64
		T::Int64
		m::Int64
		compute_loglik::Bool
		store_history::Bool
	end

	# KalmanSettings constructor
	function KalmanSettings(Y::JArray{Float64}, B::FloatArray, R::FloatArray, C::FloatArray, V::FloatArray; compute_loglik::Bool=true, store_history::Bool=true)

		# Compute default value for missing parameters
		n, T = size(Y);
		m = size(B,2);
		X0 = zeros(m);
		P0 = reshape((I-kron(C, C))\V[:], m, m);
		P0 = sym(P0);

		# Return KalmanSettings
		return KalmanSettings(Y, B, R, C, V, X0, P0, n, T, m, compute_loglik, store_history);
	end

	"""
		KalmanStatus(...)

	Define an mutable structure to manage the status of the Kalman filter and smoother.

	# Arguments
	- `t`: Current point in time
	- `loglik`: Loglikelihood
	- `X_prior`: Latest a-priori X
	- `X_post`: Latest a-posteriori X
	- `X_smooth`: Latest smoothed X
	- `P_prior`: Latest a-priori P
	- `P_post`: Latest a-posteriori P
	- `P_smooth`: Latest smoothed P
	- `history_X_prior`: History of a-priori X
	- `history_X_post`: History of a-posteriori X
	- `history_X_smooth`: History of the smoothed X
	- `history_P_prior`: History of a-priori P
	- `history_P_post`: History of a-posteriori P
	- `history_P_smooth`: History of the smoothed P
	"""
	mutable struct KalmanStatus
		t::Int64
		loglik::Union{Float64, Nothing}
		X_prior::Union{FloatVector, Nothing}
		X_post::Union{FloatVector, Nothing}
		X_smooth::Union{FloatVector, Nothing}
		P_prior::Union{FloatArray, Nothing}
		P_post::Union{FloatArray, Nothing}
		P_smooth::Union{FloatArray, Nothing}
		history_X_prior::Union{Array{FloatVector,1}, Nothing}
		history_X_post::Union{Array{FloatVector,1}, Nothing}
		history_X_smooth::Union{Array{FloatVector,1}, Nothing}
		history_P_prior::Union{Array{FloatArray,1}, Nothing}
		history_P_post::Union{Array{FloatArray,1}, Nothing}
		history_P_smooth::Union{Array{FloatArray,1}, Nothing}
	end

	# KalmanStatus constructors
	KalmanStatus() = KalmanStatus(1, [nothing for i=1:13]...);
	KalmanStatus(m::Int64, T::Int64) = KalmanStatus(1, [nothing for i=1:7]..., [zeros(m, T) for i=1:3]..., [zeros(m, m, T) for i=1:3]...);
	KalmanStatus(KS::KalmanSettings) = KalmanStatus(1, [nothing for i=1:7]..., [zeros(KS.m, KS.T) for i=1:3]..., [zeros(KS.m, KS.m, KS.T) for i=1:3]...);


	# ---------------------------------------------------------------------------------------------------------------------------
	# Functions
	# ---------------------------------------------------------------------------------------------------------------------------

	# Load
    include("$local_path/methods.jl");
	include("$local_path/coordinate_descent.jl");
	include("$local_path/kalman.jl");
	include("$local_path/kalman_new.jl");
	include("$local_path/ecm.jl");
	include("$local_path/jackknife.jl");
	include("$local_path/validation.jl");

	# Export
	export JVector, JArray, KalmanSettings, KalmanStatus;
	export mean_skipmissing, std_skipmissing, is_vector_in_matrix, sym, sym_inv, demean, lag, companion_form, ext_companion_form, no_combinations, rand_without_replacement!;
	export kalman;
	export kfilter!;
	export coordinate_descent, ecm;
	export block_jackknife, artificial_jackknife;
	export select_hyperparameters, fc_err, jackknife_err;
end
