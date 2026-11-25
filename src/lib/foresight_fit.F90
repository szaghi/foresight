!< foresight_fit, gnuplot's `fit`: nonlinear least squares by the Marquardt-Levenberg method.
module foresight_fit
!< foresight_fit, gnuplot's `fit`: nonlinear least squares by the Marquardt-Levenberg method.
!<
!< A translation of gnuplot 6.0's fit.c and matrix.c, so that a fit gives gnuplot's parameters, errors and iterations:
!<
!< - the parameters are prescaled by their initial values (each one starts at +-1; a zero one at 1e-30, unscaled);
!< - the model derivatives are one-sided differences, the step 0.001 of each scaled parameter;
!< - each step solves the least squares problem of the Jacobian over the errors, augmented by lambda times the identity,
!<   by Givens rotations; a step that does not increase chi-square is taken and lambda divided by 10, else lambda is
!<   multiplied by 10 and the step tried again; lambda starts at the root mean square of the Jacobian entries;
!< - the fit stops when chi-square decreases by no more than `limit` times itself (plus `limit_abs`), after `maxiter`
!<   iterations if set, when lambda exceeds 1e20 or chi-square is zero;
!< - the parameter errors are the square roots of the diagonal of (J^T J)^-1, scaled by sqrt(chi-square / ndf) when the
!<   data carry no errors or `errorscaling` holds (gnuplot's default); the correlations follow from the same matrix.
!<
!< `levenberg_marquardt` fits any extension of `fit_model` (values at the data points for a parameter vector; the script
!< fits user functions through it); `fit` fits a Fortran function of x; `fit_report` writes gnuplot's report.
use, intrinsic :: ieee_arithmetic, only : ieee_is_finite, ieee_is_nan, ieee_quiet_nan, ieee_value
use penf, only : I4P, I8P, R8P
use foresight_format, only : decimal_of, format_decimal, int_str

implicit none
private
public :: fit
public :: fit_report
public :: fit_result
public :: fit_settings
public :: fit_model
public :: levenberg_marquardt
public :: model_values
public :: model_function

real(R8P), parameter :: NEARLY_ZERO = 1.0e-30_R8P !< gnuplot's floor of a parameter and of chi-square.
real(R8P), parameter :: DELTA       = 0.001_R8P   !< Relative step of the numerical derivatives.
real(R8P), parameter :: MIN_LAMBDA  = 1.0e-20_R8P !< lambda is not decreased below.
real(R8P), parameter :: MAX_LAMBDA  = 1.0e20_R8P  !< The fit stops above.

type :: fit_settings
   !< gnuplot's `set fit` options.
   real(R8P)    :: limit = 1.0e-5_R8P      !< Relative change of chi-square that stops the fit (`limit`, FIT_LIMIT).
   real(R8P)    :: limit_abs = 0.0_R8P     !< Absolute part of the stopping change (`limit_abs`).
   integer(I4P) :: maxiter = 0_I4P         !< Most iterations, 0 for no limit (`maxiter`, FIT_MAXITER).
   real(R8P)    :: start_lambda = 0.0_R8P  !< First lambda, 0 for gnuplot's estimate (`start_lambda`).
   real(R8P)    :: lambda_factor = 10.0_R8P !< lambda factor up and down (`lambda_factor`).
   logical      :: prescale = .true.       !< Parameters scaled by their initial values (`prescale`).
   logical      :: errorscaling = .true.   !< Errors scaled by the reduced chi-square (`errorscaling`).
endtype fit_settings

type :: fit_result
   !< Outcome of a fit: gnuplot's FIT_* values, the parameters and their errors.
   real(R8P), allocatable        :: params(:)        !< Fitted parameters.
   real(R8P), allocatable        :: errors(:)        !< Asymptotic standard errors (`a_err`), 0 if not computable.
   real(R8P), allocatable        :: correlation(:,:) !< Correlations of the parameters, 0 if not computable.
   real(R8P)                     :: wssr = 0.0_R8P   !< Weighted sum of squared residuals (FIT_WSSR).
   real(R8P)                     :: last_wssr = 0.0_R8P !< WSSR of the iteration before the last.
   real(R8P)                     :: stdfit = 0.0_R8P !< sqrt(WSSR / ndf) (FIT_STDFIT).
   real(R8P)                     :: p = 0.0_R8P      !< p-value of chi-square (FIT_P).
   integer(I4P)                  :: ndf = 0_I4P      !< Degrees of freedom (FIT_NDF).
   integer(I4P)                  :: niter = 0_I4P    !< Iterations (FIT_NITER).
   logical                       :: converged = .false. !< Converged (FIT_CONVERGED).
   logical                       :: has_errors = .false. !< Errors and correlations computed.
   logical                       :: weighted = .false.   !< The data carried errors.
   character(len=:), allocatable :: stop_text        !< Why the fit stopped, gnuplot's sentence.
   character(len=:), allocatable :: progress         !< gnuplot's one-line progress report, iteration after iteration.
   character(len=:), allocatable :: message          !< Failure, empty on success.
endtype fit_result

type, abstract :: fit_model
   !< A model fitted by `levenberg_marquardt`: its values at the data points for a parameter vector. An object, not a
   !< procedure argument: an internal procedure passed as an argument costs gfortran an executable stack (trampoline).
   contains
      procedure(model_values), deferred, pass(self) :: values !< Values at the data points.
      procedure, pass(self) :: slopes => model_slopes         !< Slopes in x at the data points (`xyerrors`).
endtype fit_model

type, extends(fit_model) :: function_model
   !< A Fortran function of x at given abscissae, for `fit`.
   procedure(model_function), pointer, nopass :: f => null() !< Model.
   real(R8P), allocatable                     :: x(:)        !< Abscissae.
   contains
      procedure, pass(self) :: values => function_values !< Values at the abscissae.
      procedure, pass(self) :: slopes => function_slopes !< Slopes at the abscissae.
endtype function_model

abstract interface
   subroutine model_values(self, p, f, ok)
   !< Values `f` of the model at the data points for the parameters `p`; `ok` false if one is undefined.
   import :: fit_model, R8P
   class(fit_model), intent(inout) :: self !< Model.
   real(R8P), intent(in)  :: p(:) !< Parameters.
   real(R8P), intent(out) :: f(:) !< Model values, one per data point.
   logical,   intent(out) :: ok   !< Every value defined.
   endsubroutine model_values

   function model_function(x, p) result(f)
   !< Value of a model at `x` for the parameters `p`, for `fit`.
   import :: R8P
   real(R8P), intent(in) :: x    !< Independent variable.
   real(R8P), intent(in) :: p(:) !< Parameters.
   real(R8P)             :: f    !< Model value.
   endfunction model_function
endinterface

contains
   subroutine fit(model, x, y, params, names, err, settings, result, report)
   !< Fit the Fortran function `model(x, params)` to the points (`x`, `y`), from the initial `params` (updated), as
   !< gnuplot `fit f(x) 'data' using 1:2[:3] via ...`: `err` the errors of y (unit weights if absent). Silent unless
   !< `report` is given: `'-'` writes gnuplot's report to the standard error, as gnuplot's terminal, a file name writes
   !< it there (gnuplot's fit.log). `names` name the parameters in the report (`p1`, `p2`, ... if absent). On failure
   !< `result%message` says why and `params` keep their initial values.
   procedure(model_function)                            :: model     !< Model.
   real(R8P),                     intent(in)            :: x(:)      !< Abscissae.
   real(R8P),                     intent(in)            :: y(:)      !< Ordinates.
   real(R8P),                     intent(inout)         :: params(:) !< Parameters: initial values in, fitted out.
   character(len=*),              intent(in), optional  :: names(:)  !< Parameter names.
   real(R8P),                     intent(in), optional  :: err(:)    !< Errors of y.
   type(fit_settings),            intent(in), optional  :: settings  !< Fit options.
   type(fit_result),              intent(out), optional :: result    !< Outcome.
   character(len=*),              intent(in), optional  :: report    !< Report: '-' standard error, else a file.
   type(fit_result)                                     :: outcome   !< Outcome.
   type(fit_settings)                                   :: options   !< Fit options.
   character(len=:), allocatable                        :: labels(:) !< Parameter names.
   real(R8P), allocatable                               :: weights(:) !< Errors of y.
   type(function_model)                                 :: values    !< Model at the abscissae.
   integer(I4P)                                         :: k         !< Counter.

   if (present(settings)) options = settings
   allocate(weights(size(y)))
   weights = 1.0_R8P
   if (present(err)) weights = err
   if (present(names)) then
      allocate(character(len=max(1, len(names))) :: labels(size(params)))
      labels = names
   else
      allocate(character(len=11) :: labels(size(params)))
      do k = 1_I4P, size(params, kind=I4P)
         labels(k) = 'p'//int_str(int(k, I8P))
      enddo
   endif
   if (size(x) /= size(y) .or. size(weights) /= size(y)) then
      outcome%message = 'x, y and err have different sizes'
   else
      values%f => model
      values%x = x
      call levenberg_marquardt(values, y, weights, params, options, outcome, present(err))
   endif
   if (len(outcome%message) == 0) params = outcome%params
   if (present(report)) call fit_report(outcome, labels, report, 'Fortran arrays x, y', 'model(x, p)', .true.)
   if (present(result)) result = outcome
   endsubroutine fit

   subroutine function_values(self, p, f, ok)
   !< The model function at every abscissa.
   class(function_model), intent(inout) :: self !< Model.
   real(R8P),             intent(in)    :: p(:) !< Parameters.
   real(R8P),             intent(out)   :: f(:) !< Values.
   logical,               intent(out)   :: ok   !< All defined.
   integer(I4P)                         :: i    !< Counter.

   do i = 1_I4P, size(self%x, kind=I4P)
      f(i) = self%f(self%x(i), p)
   enddo
   ok = all(ieee_is_finite(f))
   endsubroutine function_values

   subroutine model_slopes(self, p, f, dfdx, ok)
   !< Slopes in x of the model at the data points for the parameters `p` (its values `f` there): none by default.
   class(fit_model), intent(inout) :: self    !< Model.
   real(R8P),        intent(in)    :: p(:)    !< Parameters.
   real(R8P),        intent(in)    :: f(:)    !< Model values.
   real(R8P),        intent(out)   :: dfdx(:) !< Slopes.
   logical,          intent(out)   :: ok      !< Every slope defined.

   dfdx = 0.0_R8P
   ok = .false.
   endsubroutine model_slopes

   subroutine function_slopes(self, p, f, dfdx, ok)
   !< Slopes of the model function at the abscissae, gnuplot's calc_derivatives: one-sided, the step
   !< max(0.001 |x|, 8e-8 (|x| + 1e-8)).
   class(function_model), intent(inout) :: self    !< Model.
   real(R8P),             intent(in)    :: p(:)    !< Parameters.
   real(R8P),             intent(in)    :: f(:)    !< Model values.
   real(R8P),             intent(out)   :: dfdx(:) !< Slopes.
   logical,               intent(out)   :: ok      !< Every slope defined.
   real(R8P)                            :: h       !< Step.
   integer(I4P)                         :: i       !< Counter.

   do i = 1_I4P, size(self%x, kind=I4P)
      h = max(DELTA * abs(self%x(i)), 8.0e-8_R8P * (abs(self%x(i)) + 1.0e-8_R8P))
      dfdx(i) = (self%f(self%x(i) + h, p) - f(i)) / h
   enddo
   ok = all(ieee_is_finite(dfdx))
   endsubroutine function_slopes

   subroutine levenberg_marquardt(model, z, err, a0, settings, result, weighted, xerr)
   !< Fit `model` (values at the data points for a parameter vector) to the data `z` of errors `err` from the initial
   !< parameters `a0`, as gnuplot's regress (see the module notes); `weighted` tells the errors were given (for the
   !< error scaling and the report). With the errors `xerr` of the abscissae (gnuplot's `xyerrors`), each point's error
   !< is the effective one, sqrt(err^2 + (f' xerr)^2), the slope f' of the model at the parameters being tried (Orear's
   !< effective variance, gnuplot's effective_error).
   class(fit_model),   intent(inout)  :: model    !< Model.
   real(R8P),          intent(in)     :: z(:)     !< Data.
   real(R8P),          intent(in)     :: err(:)   !< Errors of the data.
   real(R8P),          intent(in)     :: a0(:)    !< Initial parameters.
   type(fit_settings), intent(in)     :: settings !< Options.
   type(fit_result),   intent(out)    :: result   !< Outcome.
   logical,            intent(in)     :: weighted !< The data carry errors.
   real(R8P),          intent(in), optional :: xerr(:) !< Errors of the abscissae.
   real(R8P), allocatable             :: xe(:)    !< Errors of the abscissae (a local copy for the internal procedures:
                                                  !< nvfortran 26.9 misreads a host's optional dummy).
   logical                            :: effective !< Effective errors (`xerr` given).
   real(R8P), allocatable             :: a(:)     !< Scaled parameters.
   real(R8P), allocatable             :: scale(:) !< Parameter scales.
   real(R8P), allocatable             :: c(:,:)   !< Jacobian over the errors, n + m rows.
   real(R8P), allocatable             :: d(:)     !< Residuals over the errors, n + m.
   real(R8P), allocatable             :: covar(:,:) !< (J^T J)^-1.
   real(R8P), allocatable             :: dpar(:)  !< Errors of the scaled parameters.
   real(R8P), allocatable             :: unused(:) !< Solution not asked for.
   real(R8P)                          :: chisq    !< Chi-square.
   real(R8P)                          :: last_chisq !< Chi-square of the iteration before.
   real(R8P)                          :: lambda   !< Marquardt parameter.
   real(R8P)                          :: factor   !< Error scaling.
   integer(I4P)                       :: n        !< Data points.
   integer(I4P)                       :: m        !< Parameters.
   integer(I4P)                       :: iter     !< Iterations.
   integer(I4P)                       :: res      !< Step outcome: 1 better, 0 worse, -1 error.
   integer(I4P)                       :: i        !< Counter.
   integer(I4P)                       :: j        !< Counter.
   logical                            :: ok       !< Step computed.
   logical                            :: covar_invalid !< A non-positive variance.
   character(len=:), allocatable      :: log      !< Progress lines, copied to `result` after the iterations.

   result%message = ''
   result%stop_text = ''
   result%progress = ''
   result%weighted = weighted
   effective = present(xerr)
   if (effective) xe = xerr
   n = size(z, kind=I4P)
   m = size(a0, kind=I4P)
   allocate(result%params(m), result%errors(m), result%correlation(m, m))
   result%params = a0
   result%errors = 0.0_R8P
   result%correlation = 0.0_R8P
   if (m == 0_I4P) then
      result%message = 'no parameter to fit'
      return
   endif
   if (n < m) then
      result%message = 'Number of data points smaller than number of parameters'
      return
   endif
   if (any(.not. (err > 0.0_R8P))) then
      result%message = 'the errors must be positive'
      return
   endif
   allocate(a(m), scale(m))
   do i = 1_I4P, m
      if (a0(i) == 0.0_R8P) then
         a(i) = NEARLY_ZERO
         scale(i) = 1.0_R8P
      elseif (settings%prescale) then
         scale(i) = sign(1.0_R8P, a0(i)) * a0(i)
         a(i) = sign(1.0_R8P, a0(i))
      else
         a(i) = a0(i)
         scale(i) = 1.0_R8P
      endif
   enddo
   allocate(c(n + m, m), d(n + m))
   c = 0.0_R8P
   d = 0.0_R8P
   ! first chi-square, and gnuplot's (Schwarz's) first lambda
   call analyze(a, c, d, chisq, ok)
   if (.not. ok) return
   if (settings%start_lambda /= 0.0_R8P) then
      lambda = settings%start_lambda
   else
      lambda = 0.0_R8P
      do i = 1_I4P, n
         do j = 1_I4P, m
            lambda = lambda + c(i, j) * c(i, j)
         enddo
      enddo
      lambda = sqrt(lambda / real(n, R8P) / real(m, R8P))
   endif
   last_chisq = chisq
   iter = 0_I4P
   log = ''
   call progress_line(iter, chisq, chisq, a)
   res = 1_I4P
   do
      if (res == 1_I4P) then
         iter = iter + 1_I4P
         last_chisq = chisq
      endif
      call marquardt(res)
      if (res == 1_I4P) call progress_line(iter, chisq, last_chisq, a)
      if (res < 0_I4P) exit
      if (.not. lambda < MAX_LAMBDA) exit
      if (settings%maxiter > 0_I4P .and. iter > settings%maxiter) exit
      if (chisq == 0.0_R8P) exit
      if (res == 1_I4P .and. .not. (last_chisq - chisq > settings%limit * chisq + settings%limit_abs)) exit
   enddo
   result%progress = log
   if (res < 0_I4P) return
   ! the errors: (J^T J)^-1 from the R of the last Jacobian
   allocate(covar(m, m))
   call givens(c(1:n, :), d(1:n), .false., unused, ok)
   if (.not. ok) then
      result%message = 'Singular matrix in Givens()'
      return
   endif
   call invert_rtr(c(1:m, :), covar, ok)
   if (.not. ok) then
      result%message = 'Singular matrix in Invert_RtR'
      return
   endif
   covar_invalid = any([(covar(i, i) <= 0.0_R8P, i = 1_I4P, m)])
   if (settings%maxiter > 0_I4P .and. iter > settings%maxiter) then
      result%stop_text = 'Maximum iteration count ('//int_str(int(settings%maxiter, I8P))//') reached. Fit stopped.'
   elseif (.not. lambda < MAX_LAMBDA) then
      result%stop_text = 'The maximum lambda = '//cformat('%e', MAX_LAMBDA)//' was exceeded. Fit stopped.'
   elseif (covar_invalid) then
      result%stop_text = 'The covariance matrix is invalid. Fit did not converge properly.'
   else
      result%stop_text = 'After '//int_str(int(iter, I8P))//' iterations the fit converged.'
      result%converged = .true.
   endif
   result%ndf = n - m
   result%wssr = chisq
   result%last_wssr = last_chisq
   result%niter = iter
   if (result%ndf > 0_I4P) then
      result%stdfit = sqrt(chisq / real(result%ndf, R8P))
      result%p = 1.0_R8P - chisq_cdf(result%ndf, chisq)
   else
      result%stdfit = ieee_value(1.0_R8P, ieee_quiet_nan)
      result%p = ieee_value(1.0_R8P, ieee_quiet_nan)
   endif
   result%params = a * scale
   allocate(dpar(m))
   dpar = 0.0_R8P
   if (.not. covar_invalid) then
      do i = 1_I4P, m
         dpar(i) = sqrt(covar(i, i))
      enddo
      do i = 1_I4P, m
         do j = 1_I4P, i
            result%correlation(i, j) = covar(i, j) / (dpar(i) * dpar(j))
            result%correlation(j, i) = result%correlation(i, j)
         enddo
      enddo
   endif
   ! gnuplot: no errors with as many points as parameters, nor with a zero chi-square, when they are scaled by it
   result%has_errors = .not. covar_invalid
   if (settings%errorscaling .or. .not. weighted) then
      if (n == m .or. chisq < NEARLY_ZERO) then
         result%has_errors = .false.
         dpar = 0.0_R8P
      else
         factor = sqrt(chisq / real(n - m, R8P))
         dpar = dpar * factor
      endif
   endif
   if (.not. result%has_errors) result%correlation = 0.0_R8P
   result%errors = dpar * scale
   contains
      subroutine analyze(p, jac, res_d, chi, defined)
      !< Model values and derivatives at the scaled parameters `p`: the top rows of `jac` and `res_d`, over the errors,
      !< and chi-square (gnuplot's analyze and calculate).
      real(R8P), intent(in)    :: p(:)       !< Scaled parameters.
      real(R8P), intent(inout) :: jac(:,:)   !< Jacobian, top n rows set.
      real(R8P), intent(inout) :: res_d(:)   !< Residuals, top n set.
      real(R8P), intent(out)   :: chi        !< Chi-square.
      logical,   intent(out)   :: defined    !< Every model value defined.
      real(R8P), allocatable   :: f(:)       !< Model values.
      real(R8P), allocatable   :: high(:)    !< Model values at a moved parameter.
      real(R8P), allocatable   :: moved(:)   !< Moved parameters.
      real(R8P), allocatable   :: e(:)       !< Errors (effective ones with `xerr`).
      real(R8P), allocatable   :: dfdx(:)    !< Slopes of the model in x.
      real(R8P)                :: ta         !< Parameter moved from.
      integer(I4P)             :: k          !< Data counter.
      integer(I4P)             :: q          !< Parameter counter.

      allocate(f(n), high(n), moved(m), e(n), dfdx(n))
      e = err
      chi = 0.0_R8P
      call model%values(p * scale, f, defined)
      if (.not. defined) then
         result%message = 'Function evaluation yields NaN ("not a number") or an undefined value'
         return
      endif
      moved = p
      do q = 1_I4P, m
         ta = p(q)
         if (abs(p(q)) < NEARLY_ZERO) ta = NEARLY_ZERO
         moved(q) = ta * (1.0_R8P + DELTA)
         call model%values(moved * scale, high, defined)
         if (.not. defined) then
            result%message = 'Function evaluation yields NaN ("not a number") or an undefined value'
            return
         endif
         do k = 1_I4P, n
            jac(k, q) = (high(k) - f(k)) / (ta * DELTA)
         enddo
         moved(q) = p(q)
      enddo
      if (effective) then
         call model%slopes(p * scale, f, dfdx, defined)
         if (.not. defined) then
            result%message = 'Function evaluation yields NaN ("not a number") or an undefined value'
            return
         endif
         e = sqrt(err**2 + (dfdx * xe)**2)
      endif
      do k = 1_I4P, n
         res_d(k) = (f(k) - z(k)) / e(k)
         do q = 1_I4P, m
            jac(k, q) = jac(k, q) / e(k)
         enddo
      enddo
      chi = sumsq(res_d(1:n))
      endsubroutine analyze

      subroutine marquardt(outcome)
      !< One Marquardt step from `a` with `lambda` (gnuplot's marquardt): `outcome` 1 better (taken), 0 worse, -1 error.
      integer(I4P), intent(out) :: outcome !< Step outcome.
      real(R8P), allocatable    :: tmp_c(:,:) !< Working Jacobian.
      real(R8P), allocatable    :: tmp_d(:)   !< Working residuals.
      real(R8P), allocatable    :: da(:)      !< Step.
      real(R8P), allocatable    :: trial(:)   !< Trial parameters.
      real(R8P)                 :: tmp_chisq  !< Trial chi-square.
      logical                   :: solved     !< Step solved.
      integer(I4P)              :: q          !< Counter.

      allocate(tmp_c(n + m, m), tmp_d(n + m), trial(m))
      tmp_c = c
      tmp_d = d
      do q = 1_I4P, m
         tmp_c(n + q, q) = lambda
         tmp_d(n + q) = 0.0_R8P
      enddo
      call givens(tmp_c, tmp_d, .true., da, solved)
      if (.not. solved) then
         result%message = 'Singular matrix in Givens()'
         outcome = -1_I4P
         return
      endif
      do q = 1_I4P, m
         trial(q) = a(q) + da(q)
      enddo
      call analyze(trial, tmp_c, tmp_d, tmp_chisq, solved)
      if (.not. solved) then
         outcome = -1_I4P
         return
      endif
      if (tmp_chisq <= chisq) then
         if (lambda > MIN_LAMBDA) lambda = lambda / settings%lambda_factor
         chisq = tmp_chisq
         c(1:n, :) = tmp_c(1:n, :)
         d(1:n) = tmp_d(1:n)
         a = trial
         outcome = 1_I4P
      else
         lambda = lambda * settings%lambda_factor
         call progress_line(-1_I4P, tmp_chisq, chisq, trial)
         outcome = 0_I4P
      endif
      endsubroutine marquardt

      subroutine progress_line(it, chi, last, p)
      !< gnuplot's one-line progress report (fit_show_brief), `*` for a step not taken.
      integer(I4P), intent(in) :: it   !< Iteration, -1 for a step not taken.
      real(R8P),    intent(in) :: chi  !< Chi-square.
      real(R8P),    intent(in) :: last !< Chi-square before.
      real(R8P),    intent(in) :: p(:) !< Scaled parameters.
      character(len=:), allocatable :: line !< Line.
      character(len=:), allocatable :: number !< Iteration number.
      real(R8P)                :: ratio !< Change of chi-square over the stopping limit.
      integer(I4P)             :: q    !< Counter.

      if (it >= 0_I4P) then
         ! through a variable: ifx 2026.2 takes len() of a function result inside repeat() for a constant expression
         number = int_str(int(it, I8P))
         line = repeat(' ', 4 - min(4, len(number)))//number
      else
         line = '   *'
      endif
      ! delta / limit, undefined (gnuplot prints nan) when the limit is zero, as for an exact fit
      ratio = ieee_value(1.0_R8P, ieee_quiet_nan)
      if (settings%limit * chi + settings%limit_abs /= 0.0_R8P) &
         ratio = (chi - last) / (settings%limit * chi + settings%limit_abs)
      if (ieee_is_nan(ratio)) then
         ! C prints 0/0 as -nan, in the field width
         line = line//' '//cformat('%-17.10e', chi)//' '//field('-nan', 10_I4P)//' '//cformat('%-9.2e', lambda)
      else
         line = line//' '//cformat('%-17.10e', chi)//' '//cformat('%- 10.2e', ratio)//' '//cformat('%-9.2e', lambda)
      endif
      do q = 1_I4P, m
         line = line//' '//cformat('% 14.6e', p(q) * scale(q))
      enddo
      call append(log, line//new_line('a'))
      endsubroutine progress_line
   endsubroutine levenberg_marquardt

   pure subroutine append(text, more)
   !< Append `more` to `text` through a temporary (no `text = text//more`: see foresight#3, bug 1).
   character(len=:), allocatable, intent(inout) :: text !< Text.
   character(len=*),              intent(in)    :: more !< Appended text.
   character(len=:), allocatable                :: t    !< Grown text.
   integer(I4P)                                 :: n    !< Length before.

   n = 0_I4P
   if (allocated(text)) n = len(text, kind=I4P)
   allocate(character(len=n + len(more)) :: t)
   if (n > 0_I4P) t(1:n) = text
   t(n + 1:) = more
   ! an assignment from another variable, not move_alloc: nvfortran 26.9 keeps the old length of a deferred-length
   ! character scalar moved so
   text = t
   endsubroutine append

   pure subroutine givens(c, d, solve, x, ok)
   !< gnuplot's Givens: the QR decomposition of `c` (N x n, N >= n) by Givens rotations in place, R in its top n rows,
   !< `d` rotated along; with `solve`, `x` solves R x + d = 0 by back substitution. `ok` false on a singular matrix.
   real(R8P),              intent(inout) :: c(:,:) !< Matrix.
   real(R8P),              intent(inout) :: d(:)   !< Right-hand side.
   logical,                intent(in)    :: solve  !< Solve for `x`.
   real(R8P), allocatable, intent(out)   :: x(:)   !< Solution.
   logical,                intent(out)   :: ok     !< Not singular.
   real(R8P)                             :: w      !< Rotated diagonal.
   real(R8P)                             :: gamma  !< Cosine.
   real(R8P)                             :: sigma  !< Sine.
   real(R8P)                             :: temp   !< Rotation buffer.
   real(R8P)                             :: s      !< Back substitution sum.
   integer(I4P)                          :: big_n  !< Rows.
   integer(I4P)                          :: n      !< Columns.
   integer(I4P)                          :: i      !< Counter.
   integer(I4P)                          :: j      !< Counter.
   integer(I4P)                          :: k      !< Counter.

   ok = .true.
   big_n = size(c, 1, kind=I4P)
   n = size(c, 2, kind=I4P)
   allocate(x(n))
   x = 0.0_R8P
   do j = 1_I4P, n
      do i = j + 1_I4P, big_n
         if (c(i, j) == 0.0_R8P) cycle
         if (abs(c(j, j)) < epsilon(1.0_R8P) * abs(c(i, j))) then
            w = -c(i, j)
            gamma = 0.0_R8P
            sigma = 1.0_R8P
         else
            w = sign(1.0_R8P, c(j, j)) * sqrt(c(j, j) * c(j, j) + c(i, j) * c(i, j))
            if (w == 0.0_R8P) then
               ok = .false.
               return
            endif
            gamma = c(j, j) / w
            sigma = -c(i, j) / w
         endif
         c(j, j) = w
         ! gnuplot stores the rotation in c(i, j); unused afterwards
         c(i, j) = 0.0_R8P
         do k = j + 1_I4P, n
            temp = gamma * c(j, k) - sigma * c(i, k)
            c(i, k) = sigma * c(j, k) + gamma * c(i, k)
            c(j, k) = temp
         enddo
         if (solve) then
            temp = gamma * d(j) - sigma * d(i)
            d(i) = sigma * d(j) + gamma * d(i)
            d(j) = temp
         endif
      enddo
   enddo
   if (.not. solve) return
   do i = n, 1_I4P, -1_I4P
      s = d(i)
      do k = i + 1_I4P, n
         s = s + c(i, k) * x(k)
      enddo
      if (c(i, i) == 0.0_R8P) then
         ok = .false.
         return
      endif
      x(i) = -s / c(i, i)
   enddo
   endsubroutine givens

   pure subroutine invert_rtr(r, inv, ok)
   !< gnuplot's Invert_RtR: (R^T R)^-1 of the upper triangular `r` (n x n), its lower triangle in `inv` (the upper one
   !< mirrored). `ok` false on a zero diagonal.
   real(R8P),    intent(in)  :: r(:,:)   !< Upper triangular matrix.
   real(R8P),    intent(out) :: inv(:,:) !< Inverse of R^T R.
   logical,      intent(out) :: ok       !< Regular.
   real(R8P)                 :: s        !< Substitution sum.
   integer(I4P)              :: n        !< Size.
   integer(I4P)              :: i        !< Counter.
   integer(I4P)              :: j        !< Counter.
   integer(I4P)              :: k        !< Counter.

   n = size(r, 1, kind=I4P)
   ok = .true.
   inv = 0.0_R8P
   do i = 1_I4P, n
      inv(i, i) = 1.0_R8P
      if (r(i, i) == 0.0_R8P) then
         ok = .false.
         return
      endif
   enddo
   ! forward substitution: R^T B = I
   do k = 1_I4P, n
      do i = k, n
         s = inv(i, k)
         do j = k, i - 1_I4P
            s = s - r(j, i) * inv(j, k)
         enddo
         inv(i, k) = s / r(i, i)
      enddo
   enddo
   ! backward substitution: R A = B
   do k = 1_I4P, n
      do i = n, k, -1_I4P
         s = inv(i, k)
         do j = i + 1_I4P, n
            s = s - r(i, j) * inv(j, k)
         enddo
         inv(i, k) = s / r(i, i)
      enddo
   enddo
   do i = 1_I4P, n
      do j = i + 1_I4P, n
         inv(i, j) = inv(j, i)
      enddo
   enddo
   endsubroutine invert_rtr

   pure function sumsq(x) result(s)
   !< Sum of the squares of `x`, compensated (Neumaier), as gnuplot's sumsq_vec.
   real(R8P), intent(in) :: x(:) !< Values.
   real(R8P)             :: s    !< Sum of squares.
   real(R8P)             :: c    !< Compensation.
   real(R8P)             :: xi   !< Square.
   real(R8P)             :: t    !< Partial sum.
   integer(I4P)          :: i    !< Counter.

   s = 0.0_R8P
   if (size(x) == 0) return
   c = 0.0_R8P
   s = x(1) * x(1)
   do i = 2_I4P, size(x, kind=I4P)
      xi = x(i) * x(i)
      t = s + xi
      if (abs(s) >= abs(xi)) then
         c = c + ((s - t) + xi)
      else
         c = c + ((xi - t) + s)
      endif
      s = t
   enddo
   s = s + c
   endfunction sumsq

   pure function chisq_cdf(dof, chisq) result(p)
   !< Chi-square distribution of `dof` degrees of freedom at `chisq`: the regularized lower incomplete gamma function
   !< P(dof / 2, chisq / 2) (series below a + 1, continued fraction above).
   integer(I4P), intent(in) :: dof   !< Degrees of freedom.
   real(R8P),    intent(in) :: chisq !< Chi-square.
   real(R8P)                :: p     !< Probability.
   real(R8P)                :: a     !< Shape.
   real(R8P)                :: x     !< Argument.
   real(R8P)                :: term  !< Series term.
   real(R8P)                :: total !< Series sum.
   real(R8P)                :: b     !< Continued fraction terms (modified Lentz).
   real(R8P)                :: cc    !< Lentz C.
   real(R8P)                :: dd    !< Lentz D.
   real(R8P)                :: h     !< Fraction value.
   real(R8P)                :: an    !< Numerator.
   real(R8P)                :: del   !< Factor.
   real(R8P), parameter     :: TINY = 1.0e-300_R8P !< Lentz floor.
   integer(I4P)             :: k     !< Counter.

   p = 0.0_R8P
   if (.not. chisq > 0.0_R8P .or. dof <= 0_I4P) return
   a = 0.5_R8P * real(dof, R8P)
   x = 0.5_R8P * chisq
   if (x < a + 1.0_R8P) then
      term = 1.0_R8P / a
      total = term
      do k = 1_I4P, 1000_I4P
         term = term * x / (a + real(k, R8P))
         total = total + term
         if (abs(term) < abs(total) * 1.0e-16_R8P) exit
      enddo
      p = total * exp(-x + a * log(x) - log_gamma(a))
   else
      b = x + 1.0_R8P - a
      cc = 1.0_R8P / TINY
      dd = 1.0_R8P / b
      h = dd
      do k = 1_I4P, 1000_I4P
         an = -real(k, R8P) * (real(k, R8P) - a)
         b = b + 2.0_R8P
         dd = an * dd + b
         if (abs(dd) < TINY) dd = TINY
         cc = b + an / cc
         if (abs(cc) < TINY) cc = TINY
         dd = 1.0_R8P / dd
         del = dd * cc
         h = h * del
         if (abs(del - 1.0_R8P) < 1.0e-16_R8P) exit
      enddo
      p = 1.0_R8P - exp(-x + a * log(x) - log_gamma(a)) * h
   endif
   endfunction chisq_cdf

   function cformat(format, v) result(text)
   !< `v` formatted by the printf `format` (`%g`, `%e`, `%f` with flags, width, precision), from its 15 significant
   !< digits (foresight_format), as C would print it.
   character(len=*), intent(in)  :: format !< Format.
   real(R8P),        intent(in)  :: v      !< Value.
   character(len=:), allocatable :: text   !< Text.
   character(len=:), allocatable :: sup    !< Superscript, unused.
   integer(I8P)                  :: n      !< Mantissa.
   integer(I4P)                  :: e      !< Exponent.

   if (ieee_is_nan(v)) then
      text = 'nan'
      return
   elseif (.not. ieee_is_finite(v)) then
      text = trim(merge('-inf', 'inf ', v < 0.0_R8P))
      return
   endif
   call decimal_of(v, n, e)
   call format_decimal(format, n, e, text, sup)
   endfunction cformat

   pure function field(text, width) result(padded)
   !< `text` left-aligned in `width` characters, cut beyond (printf `%-W.Ws`).
   character(len=*), intent(in)  :: text   !< Text.
   integer(I4P),     intent(in)  :: width  !< Width.
   character(len=:), allocatable :: padded !< Text.

   padded = text(1:min(len(text), width))//repeat(' ', max(0, width - len(text)))
   endfunction field

   subroutine fit_report(result, names, destination, source, function_text, progress)
   !< Write gnuplot's fit report of `result`, for the parameters `names`: on the standard error (`destination` `'-'`,
   !< gnuplot's terminal output: with `progress` the progress lines (gnuplot's `brief`), then the stop sentence and
   !< the results) or appended to the file `destination` (gnuplot's fit.log: a header naming the data `source` and the
   !< `function_text`, the first and last progress lines, the results).
   type(fit_result), intent(in) :: result        !< Outcome.
   character(len=*), intent(in) :: names(:)      !< Parameter names.
   character(len=*), intent(in) :: destination   !< '-' or a file name.
   character(len=*), intent(in) :: source        !< Data description.
   character(len=*), intent(in) :: function_text !< Fitted function.
   logical,          intent(in) :: progress      !< Terminal: with the progress lines.
   character(len=:), allocatable :: text         !< Report.
   character(len=:), allocatable :: header       !< Progress header.
   character(len=8)              :: date         !< Date.
   character(len=10)             :: time         !< Time.
   integer(I4P)                  :: unit         !< File unit.
   integer(I4P)                  :: ios          !< I/O status.
   integer(I4P)                  :: k            !< Counter.
   integer(I4P)                  :: first        !< End of the first progress line.

   header = 'iter      chisq       delta/lim  lambda  '
   do k = 1_I4P, size(names, kind=I4P)
      header = header//' '//field(trim(names(k)), 13_I4P)
   enddo
   if (destination == '-') then
      text = new_line('a')
      if (progress) text = header//new_line('a')//result%progress//header//new_line('a')//new_line('a')
   else
      call date_and_time(date, time)
      text = new_line('a')//new_line('a')//repeat('*', 79)//new_line('a')//date(1:4)//'-'//date(5:6)//'-'//date(7:8)// &
             ' '//time(1:2)//':'//time(3:4)//':'//time(5:6)//new_line('a')//new_line('a')//new_line('a')// &
             'FIT:    data read from '//source//new_line('a')// &
             '        format = '//merge('x:z:s', 'x:z  ', result%weighted)//new_line('a')// &
             '        #datapoints = '//int_str(int(result%ndf + size(names), I8P))//new_line('a')// &
             '        '//merge('residuals are weighted by the errors        ', &
                               'residuals are weighted equally (unit weight)', result%weighted)//new_line('a')// &
             new_line('a')//'function used for fitting: '//function_text//new_line('a')// &
             'fitted parameters initialized with current variable values'//new_line('a')//new_line('a')//header// &
             new_line('a')
      first = index(result%progress, new_line('a'))
      if (first > 0) text = text//result%progress(1:first)
      text = text//last_line(result%progress)//new_line('a')
   endif
   if (len(result%message) > 0) then
      text = text//new_line('a')//result%message//new_line('a')
   else
      text = text//result%stop_text//new_line('a')//results_text(result, names)
   endif
   if (destination == '-') then
      write(0, '(A)', advance='no') text
   else
      open(newunit=unit, file=destination, action='write', position='append', status='unknown', iostat=ios)
      if (ios /= 0_I4P) return
      write(unit, '(A)', advance='no') text
      close(unit)
   endif
   contains
      pure function last_line(lines) result(line)
      !< The last line of `lines`, a progress line of a taken step (not `*`), with its new line.
      character(len=*), intent(in)  :: lines !< Lines.
      character(len=:), allocatable :: line  !< Last line.
      integer(I4P)                  :: e     !< End.
      integer(I4P)                  :: b     !< Start.

      line = ''
      e = len(lines, kind=I4P)
      do while (e > 0_I4P)
         b = index(lines(1:e - 1), new_line('a'), back=.true.) + 1_I4P
         if (lines(b:b + 3) /= '   *') then
            line = lines(b:e)
            return
         endif
         e = b - 1_I4P
      enddo
      endfunction last_line
   endsubroutine fit_report

   function results_text(result, names) result(text)
   !< gnuplot's final results (show_results): sums of squares, degrees of freedom, the parameters and their errors, the
   !< correlation matrix.
   type(fit_result), intent(in)  :: result !< Outcome.
   character(len=*), intent(in)  :: names(:) !< Parameter names.
   character(len=:), allocatable :: text   !< Results.
   character(len=1), parameter   :: NL = new_line('a') !< New line.
   real(R8P)                     :: percent !< Relative error [%].
   integer(I4P)                  :: i      !< Counter.
   integer(I4P)                  :: j      !< Counter.

   text = 'final sum of squares of residuals : '//cformat('%g', result%wssr)//NL
   if (result%wssr > NEARLY_ZERO) then
      text = text//'rel. change during last iteration : '// &
             cformat('%g', (result%wssr - result%last_wssr) / result%wssr)//NL//NL
   else
      text = text//'abs. change during last iteration : '//cformat('%g', result%wssr - result%last_wssr)//NL//NL
   endif
   if (.not. result%has_errors) then
      if (result%ndf == 0_I4P) then
         text = text//NL//'Exactly as many data points as there are parameters.'//NL// &
                'In this degenerate case, all errors are zero by definition.'//NL//NL
      elseif (result%wssr < NEARLY_ZERO) then
         text = text//NL//'Hmmmm.... Sum of squared residuals is zero. Can''t compute errors.'//NL//NL
      endif
      text = text//'Final set of parameters '//NL//'======================= '//NL//NL
      do i = 1_I4P, size(names, kind=I4P)
         text = text//field(trim(names(i)), 15_I4P)//' = '//cformat('%-15g', result%params(i))//NL
      enddo
      return
   endif
   text = text//'degrees of freedom    (FIT_NDF)                        : '//int_str(int(result%ndf, I8P))//NL// &
          'rms of residuals      (FIT_STDFIT) = sqrt(WSSR/ndf)    : '//cformat('%g', result%stdfit)//NL// &
          'variance of residuals (reduced chisquare) = WSSR/ndf   : '// &
          cformat('%g', result%wssr / real(result%ndf, R8P))//NL
   if (result%weighted) text = text//'p-value of the Chisq distribution (FIT_P)              : '// &
                               cformat('%g', result%p)//NL
   text = text//NL//'Final set of parameters            Asymptotic Standard Error'//NL// &
          '=======================            =========================='//NL
   do i = 1_I4P, size(names, kind=I4P)
      percent = 0.0_R8P
      if (abs(result%params(i)) >= NEARLY_ZERO) percent = abs(100.0_R8P * result%errors(i) / result%params(i))
      text = text//field(trim(names(i)), 15_I4P)//' = '//cformat('%-15g', result%params(i))//'  +/- '// &
             cformat('%-12.4g', result%errors(i))//' ('//cformat('%.4g', percent)//'%)'//NL
   enddo
   if (size(names) > 1) then
      text = text//NL//'correlation matrix of the fit parameters:'//NL//'                '
      do j = 1_I4P, size(names, kind=I4P)
         text = text//field(trim(names(j)), 6_I4P)//' '
      enddo
      text = text//NL
      do i = 1_I4P, size(names, kind=I4P)
         text = text//field(trim(names(i)), 15_I4P)
         do j = 1_I4P, i
            text = text//cformat('%6.3f', result%correlation(i, j))//' '
         enddo
         text = text//NL
      enddo
   endif
   endfunction results_text
endmodule foresight_fit
