module Model.OpenFlex exposing
    ( Failure
    , Params
    , Vars
    , bookParams
    , carry
    , flows
    , sectors
    , simulate
    , steadyState
    , step
    )

{-| Model OPENFLEX from Godley and Lavoie, "Monetary Economics" (2007),
chapter 12: two countries that trade goods and hold each other's bills, with
a floating exchange rate.

The book calls the countries UK and US. Here the UK plays the home country:
it sets its own interest rate and lets its currency float. `xr_uk` is the
value of the home currency in units of the foreign one, so a fall is a
depreciation.

Variable and parameter names are the book's, kept as they are so that each
line can be checked against the book and against the `sfcr` replication the
equations were taken from. A `_k` marks a real (volume) quantity, `_d` a
demand and `_s` a supply. `b_ukus` are US bills held in the UK, `b_usuk` UK
bills held in the US, and `b_cb` the holdings of a central bank.

Two things differ from the book. Gold is left out: it never changes hands in
this version of the model, so it only added a constant to each central
bank's balance sheet. And the home central bank's bill holdings follow the
book's own alternative equation 12.82A (it holds the bills nobody else
does), which keeps the accounts from drifting apart over long runs.

Six things are added, and all are switched off in the book's baseline. The
home wage can follow consumer prices (`kappa_uk`) and unemployment
(`beta_uk`, against a labour force `lf_uk`), a share `wspeed_uk` of wages
being reset each period. Home households can spend less of their income when
the real interest rate stands above `rstar_uk` (`zeta_uk`). The
home government can pay transfers to households (`tr_k_uk`). Foreigners can
buy a share of home firms from home households every period (`fdi_flow_uk`,
as a share of output) and receive profits on what they own (`rho_uk`). And
the economy can sit on a growth path: every value is measured relative to its
trend, where real quantities grow at `trend` a period and each country's
prices at its `infl`. See `carry`.

The body of `sweep`, the list of fields and the steady state are generated
from one list of equations, the same list that produced the prototype these
numbers were checked against.

-}

import Sfc.Matrix exposing (Flow, Sector(..))
import Sfc.Solver as Solver



-- PARAMETERS


type alias Params =
    { alpha1_uk : Float
    , alpha1_us : Float
    , alpha2_uk : Float
    , alpha2_us : Float
    , eps0 : Float
    , eps1 : Float
    , eps2 : Float
    , lambda10 : Float
    , lambda11 : Float
    , lambda12 : Float
    , lambda20 : Float
    , lambda21 : Float
    , lambda22 : Float
    , lambda40 : Float
    , lambda41 : Float
    , lambda42 : Float
    , lambda50 : Float
    , lambda51 : Float
    , lambda52 : Float
    , mu0 : Float
    , mu1 : Float
    , mu2 : Float
    , nu0m : Float
    , nu0x : Float
    , nu1m : Float
    , nu1x : Float
    , phi_uk : Float
    , phi_us : Float
    , theta_uk : Float
    , theta_us : Float
    , dxre_us : Float
    , dxre_uk : Float
    , g_k_uk : Float
    , g_k_us : Float
    , pr_uk : Float
    , pr_us : Float
    , r_uk : Float
    , r_us : Float
    , w_uk : Float
    , w_us : Float
    , b_cb_ukus_s : Float
    , trend : Float
    , infl_uk : Float
    , infl_us : Float
    , tr_k_uk : Float
    , rho_uk : Float
    , fdi_flow_uk : Float
    , kappa_uk : Float
    , pref_uk : Float
    , wspeed_uk : Float
    , beta_uk : Float
    , lf_uk : Float
    , ustar_uk : Float
    , zeta_uk : Float
    , rstar_uk : Float
    }


{-| The book's baseline. Both countries are identical.
-}
bookParams : Params
bookParams =
    { alpha1_uk = 0.75
    , alpha1_us = 0.75
    , alpha2_uk = 0.13333
    , alpha2_us = 0.13333
    , eps0 = -2.1
    , eps1 = 0.7
    , eps2 = 1
    , lambda10 = 0.7
    , lambda11 = 5
    , lambda12 = 5
    , lambda20 = 0.25
    , lambda21 = 5
    , lambda22 = 5
    , lambda40 = 0.7
    , lambda41 = 5
    , lambda42 = 5
    , lambda50 = 0.25
    , lambda51 = 5
    , lambda52 = 5
    , mu0 = -2.1
    , mu1 = 0.7
    , mu2 = 1
    , nu0m = -0.00001
    , nu0x = -0.00001
    , nu1m = 0.7
    , nu1x = 0.5
    , phi_uk = 0.2381
    , phi_us = 0.2381
    , theta_uk = 0.2
    , theta_us = 0.2
    , dxre_us = 0
    , dxre_uk = 0
    , g_k_uk = 16
    , g_k_us = 16
    , pr_uk = 1.3333
    , pr_us = 1.3333
    , r_uk = 0.03
    , r_us = 0.03
    , w_uk = 1
    , w_us = 1
    , b_cb_ukus_s = 0.02031
    , trend = 1
    , infl_uk = 1
    , infl_us = 1
    , tr_k_uk = 0
    , rho_uk = 0
    , fdi_flow_uk = 0
    , kappa_uk = 0
    , pref_uk = 1
    , wspeed_uk = 1
    , beta_uk = 0
    , lf_uk = 1000000
    , ustar_uk = 1
    , zeta_uk = 0
    , rstar_uk = 0
    }



-- VARIABLES


type alias Vars =
    { xr_us : Float
    , pm_uk : Float
    , px_uk : Float
    , px_us : Float
    , pm_us : Float
    , x_k_uk : Float
    , im_k_uk : Float
    , x_k_us : Float
    , im_k_us : Float
    , x_uk : Float
    , x_us : Float
    , im_uk : Float
    , im_us : Float
    , remit_uk : Float
    , t_uk : Float
    , t_us : Float
    , tr_uk : Float
    , yd_uk : Float
    , yd_us : Float
    , ydhs_k_uk : Float
    , ydhs_k_us : Float
    , ydhse_k_uk : Float
    , ydhse_k_us : Float
    , c_k_uk : Float
    , c_k_us : Float
    , s_k_uk : Float
    , s_k_us : Float
    , y_k_uk : Float
    , y_k_us : Float
    , n_uk : Float
    , u_uk : Float
    , n_us : Float
    , wage_uk : Float
    , ps_uk : Float
    , ps_us : Float
    , s_uk : Float
    , s_us : Float
    , pds_uk : Float
    , pds_us : Float
    , y_uk : Float
    , y_us : Float
    , py_uk : Float
    , py_us : Float
    , cons_uk : Float
    , cons_us : Float
    , g_uk : Float
    , g_us : Float
    , fdi_in_uk : Float
    , fdi_uk : Float
    , gpi_uk : Float
    , v_uk : Float
    , v_us : Float
    , v_k_uk : Float
    , v_k_us : Float
    , f_cb_uk : Float
    , f_cb_us : Float
    , b_uk_s : Float
    , b_us_s : Float
    , b_ukuk_d : Float
    , b_ukus_d : Float
    , h_uk_d : Float
    , b_usus_d : Float
    , b_usuk_d : Float
    , h_us_d : Float
    , b_cb_usus_d : Float
    , b_usuk_s : Float
    , b_cb_ukuk_d : Float
    , b_ukus_s : Float
    , cab_uk : Float
    , psbr_uk : Float
    , psbr_us : Float
    , xr_uk : Float
    }


{-| The steady state of the baseline: stepping from here changes nothing.
-}
steadyState : Vars
steadyState =
    { xr_us = 0.9997000741967625
    , pm_uk = 0.9562762565324923
    , px_uk = 0.9563330155691299
    , px_us = 0.9565631545049544
    , pm_us = 0.956619930570199
    , x_k_uk = 11.926764499300376
    , im_k_uk = 11.928312282144539
    , x_k_us = 11.928312282144539
    , im_k_us = 11.926764499300376
    , x_uk = 11.405958659598772
    , x_us = 11.410184024528371
    , im_uk = 11.40676181591973
    , im_us = 11.40938062724784
    , remit_uk = 0
    , t_uk = 19.46320060295118
    , t_us = 19.46558933831728
    , tr_uk = 0
    , yd_uk = 77.85280241180472
    , yd_us = 77.86235735326912
    , ydhs_k_uk = 81.39532738726916
    , ydhs_k_us = 81.40387252121769
    , ydhse_k_uk = 81.39532738726916
    , ydhse_k_us = 81.40387252121769
    , c_k_uk = 81.39532738726913
    , c_k_us = 81.4038725212177
    , s_k_uk = 109.32209188656951
    , s_k_us = 109.33218480336225
    , y_k_uk = 97.39377960442496
    , y_k_us = 97.40542030406188
    , n_uk = 73.04716088234079
    , u_uk = 0.9999269528391177
    , n_us = 73.05589162533704
    , wage_uk = 1
    , ps_uk = 0.9564617717085792
    , ps_us = 0.9565020013458044
    , s_uk = 104.56240169271636
    , s_us = 104.57645357592534
    , pds_uk = 0.9564775388320568
    , pds_us = 0.956494512382989
    , y_uk = 93.15563987679664
    , y_us = 93.1670729486775
    , py_uk = 0.956484492697152
    , py_us = 0.9564875615530029
    , cons_uk = 77.85280241180469
    , cons_us = 77.86235735326913
    , g_uk = 15.303640621312908
    , g_us = 15.303912198127824
    , fdi_in_uk = 0
    , fdi_uk = 0
    , gpi_uk = 1
    , v_uk = 145.97765396348274
    , v_us = 145.99556992662787
    , v_k_uk = 152.6200543524883
    , v_k_us = 152.63607687920526
    , f_cb_uk = 0.21895299289676656
    , f_cb_us = 0.21899335488994195
    , b_uk_s = 145.950432484502
    , b_us_s = 146.02234983597918
    , b_ukuk_d = 102.18435777443791
    , b_ukus_d = 36.494413490870684
    , h_uk_d = 7.29888269817414
    , b_usus_d = 102.1968989486395
    , b_usuk_d = 36.498892481656966
    , h_us_d = 7.299778496331399
    , b_cb_usus_d = 7.299778496331399
    , b_usuk_s = 36.487945522012126
    , b_cb_ukuk_d = 7.278129188051949
    , b_ukus_s = 36.50536239100828
    , cab_uk = 7.567731163948821e-15
    , psbr_uk = 2.2037927038809357e-14
    , psbr_us = -2.42861286636753e-14
    , xr_uk = 1.000300015785713
    }



-- TRENDS


{-| Last period's values, measured against this period's trend.

Real quantities grow at `trend` a period, each country's prices at its
`infl`, amounts of money at both, and an exchange rate at the ratio of the
two inflations. So relative to this period's trend, last period's value is
smaller by one period of growth. With no growth and no inflation this
changes nothing.

-}
carry : Params -> Vars -> Vars
carry params vars =
    { xr_us = vars.xr_us / (params.infl_uk / params.infl_us)
    , pm_uk = vars.pm_uk / params.infl_uk
    , px_uk = vars.px_uk / params.infl_uk
    , px_us = vars.px_us / params.infl_us
    , pm_us = vars.pm_us / params.infl_us
    , x_k_uk = vars.x_k_uk / params.trend
    , im_k_uk = vars.im_k_uk / params.trend
    , x_k_us = vars.x_k_us / params.trend
    , im_k_us = vars.im_k_us / params.trend
    , x_uk = vars.x_uk / (params.trend * params.infl_uk)
    , x_us = vars.x_us / (params.trend * params.infl_us)
    , im_uk = vars.im_uk / (params.trend * params.infl_uk)
    , im_us = vars.im_us / (params.trend * params.infl_us)
    , remit_uk = vars.remit_uk / (params.trend * params.infl_uk)
    , t_uk = vars.t_uk / (params.trend * params.infl_uk)
    , t_us = vars.t_us / (params.trend * params.infl_us)
    , tr_uk = vars.tr_uk / (params.trend * params.infl_uk)
    , yd_uk = vars.yd_uk / (params.trend * params.infl_uk)
    , yd_us = vars.yd_us / (params.trend * params.infl_us)
    , ydhs_k_uk = vars.ydhs_k_uk / params.trend
    , ydhs_k_us = vars.ydhs_k_us / params.trend
    , ydhse_k_uk = vars.ydhse_k_uk / params.trend
    , ydhse_k_us = vars.ydhse_k_us / params.trend
    , c_k_uk = vars.c_k_uk / params.trend
    , c_k_us = vars.c_k_us / params.trend
    , s_k_uk = vars.s_k_uk / params.trend
    , s_k_us = vars.s_k_us / params.trend
    , y_k_uk = vars.y_k_uk / params.trend
    , y_k_us = vars.y_k_us / params.trend
    , n_uk = vars.n_uk / params.trend
    , u_uk = vars.u_uk / 1
    , n_us = vars.n_us / params.trend
    , wage_uk = vars.wage_uk / params.infl_uk
    , ps_uk = vars.ps_uk / params.infl_uk
    , ps_us = vars.ps_us / params.infl_us
    , s_uk = vars.s_uk / (params.trend * params.infl_uk)
    , s_us = vars.s_us / (params.trend * params.infl_us)
    , pds_uk = vars.pds_uk / params.infl_uk
    , pds_us = vars.pds_us / params.infl_us
    , y_uk = vars.y_uk / (params.trend * params.infl_uk)
    , y_us = vars.y_us / (params.trend * params.infl_us)
    , py_uk = vars.py_uk / params.infl_uk
    , py_us = vars.py_us / params.infl_us
    , cons_uk = vars.cons_uk / (params.trend * params.infl_uk)
    , cons_us = vars.cons_us / (params.trend * params.infl_us)
    , g_uk = vars.g_uk / (params.trend * params.infl_uk)
    , g_us = vars.g_us / (params.trend * params.infl_us)
    , fdi_in_uk = vars.fdi_in_uk / (params.trend * params.infl_uk)
    , fdi_uk = vars.fdi_uk / (params.trend * params.infl_uk)
    , gpi_uk = vars.gpi_uk / 1
    , v_uk = vars.v_uk / (params.trend * params.infl_uk)
    , v_us = vars.v_us / (params.trend * params.infl_us)
    , v_k_uk = vars.v_k_uk / params.trend
    , v_k_us = vars.v_k_us / params.trend
    , f_cb_uk = vars.f_cb_uk / (params.trend * params.infl_uk)
    , f_cb_us = vars.f_cb_us / (params.trend * params.infl_us)
    , b_uk_s = vars.b_uk_s / (params.trend * params.infl_uk)
    , b_us_s = vars.b_us_s / (params.trend * params.infl_us)
    , b_ukuk_d = vars.b_ukuk_d / (params.trend * params.infl_uk)
    , b_ukus_d = vars.b_ukus_d / (params.trend * params.infl_uk)
    , h_uk_d = vars.h_uk_d / (params.trend * params.infl_uk)
    , b_usus_d = vars.b_usus_d / (params.trend * params.infl_us)
    , b_usuk_d = vars.b_usuk_d / (params.trend * params.infl_us)
    , h_us_d = vars.h_us_d / (params.trend * params.infl_us)
    , b_cb_usus_d = vars.b_cb_usus_d / (params.trend * params.infl_us)
    , b_usuk_s = vars.b_usuk_s / (params.trend * params.infl_uk)
    , b_cb_ukuk_d = vars.b_cb_ukuk_d / (params.trend * params.infl_uk)
    , b_ukus_s = vars.b_ukus_s / (params.trend * params.infl_us)
    , cab_uk = vars.cab_uk / (params.trend * params.infl_uk)
    , psbr_uk = vars.psbr_uk / (params.trend * params.infl_uk)
    , psbr_us = vars.psbr_us / (params.trend * params.infl_us)
    , xr_uk = vars.xr_uk / (params.infl_us / params.infl_uk)
    }



-- EQUATIONS


exp : Float -> Float
exp x =
    e ^ x


ln : Float -> Float
ln x =
    logBase e x


{-| One pass over every equation, in order. Each one uses the values already
computed in this pass where there are any, and the previous guess otherwise.
A period is solved by repeating the pass until nothing changes. `lagged` is
the previous period as `carry` returns it.

The comment above each line is the equation's number in the book.

-}
sweep : Params -> Vars -> Params -> Vars -> Vars
sweep laggedParams lagged params guess =
    let
        -- [12.86] US exchange rate
        xr_us =
            1 / guess.xr_uk

        -- [12.21] import prices in UK
        pm_uk =
            exp (params.nu0m + params.nu1m * ln guess.py_us + (1 - params.nu1m) * ln guess.py_uk - params.nu1m * ln guess.xr_uk)

        -- [12.22] export prices in UK
        px_uk =
            exp (params.nu0x + params.nu1x * ln guess.py_us + (1 - params.nu1x) * ln guess.py_uk - params.nu1x * ln guess.xr_uk)

        -- [12.23] export prices in US
        px_us =
            pm_uk * guess.xr_uk

        -- [12.24] import prices in US
        pm_us =
            px_uk * guess.xr_uk

        -- [12.25] real exports from UK
        x_k_uk =
            exp (params.eps0 - params.eps1 * ln (pm_us / guess.py_us) + params.eps2 * ln guess.y_k_us)

        -- [12.26] real imports of UK
        im_k_uk =
            exp (params.mu0 - params.mu1 * ln (lagged.pm_uk / lagged.py_uk) + params.mu2 * ln guess.y_k_uk)

        -- [12.27] real exports from US
        x_k_us =
            im_k_uk

        -- [12.28] real imports of US
        im_k_us =
            x_k_uk

        -- [12.29] exports of UK
        x_uk =
            x_k_uk * px_uk

        -- [12.30] exports of US
        x_us =
            x_k_us * px_us

        -- [12.31] imports of UK
        im_uk =
            im_k_uk * pm_uk

        -- [12.32] imports of US
        im_us =
            im_k_us * pm_us

        -- profits that foreign-owned firms in the UK send abroad (not in the book)
        remit_uk =
            laggedParams.rho_uk * lagged.fdi_uk

        -- [12.7] taxes in UK; household income is output less the profits sent abroad
        t_uk =
            params.theta_uk * (guess.y_uk - remit_uk + laggedParams.r_uk * lagged.b_ukuk_d + xr_us * laggedParams.r_us * lagged.b_ukus_s)

        -- [12.8] taxes in US
        t_us =
            params.theta_us * (guess.y_us + guess.xr_uk * remit_uk + laggedParams.r_us * lagged.b_usus_d + guess.xr_uk * laggedParams.r_uk * lagged.b_usuk_s)

        -- government transfers to UK households, fixed in real terms (not in the book)
        tr_uk =
            params.tr_k_uk * guess.pds_uk

        -- [12.1] disposable income in UK, plus transfers
        yd_uk =
            (guess.y_uk - remit_uk + laggedParams.r_uk * lagged.b_ukuk_d + xr_us * laggedParams.r_us * lagged.b_ukus_s) * (1 - params.theta_uk) + (xr_us - lagged.xr_us) * lagged.b_ukus_s + tr_uk

        -- [12.4] disposable income in US
        yd_us =
            (guess.y_us + guess.xr_uk * remit_uk + laggedParams.r_us * lagged.b_usus_d + guess.xr_uk * laggedParams.r_uk * lagged.b_usuk_s) * (1 - params.theta_us) + (guess.xr_uk - lagged.xr_uk) * lagged.b_usuk_s

        -- [12.35] real Haig-Simons disposable income in UK
        ydhs_k_uk =
            yd_uk / guess.pds_uk - lagged.v_k_uk * (guess.pds_uk - lagged.pds_uk) / guess.pds_uk

        -- [12.36] real Haig-Simons disposable income in US
        ydhs_k_us =
            yd_us / guess.pds_us - lagged.v_k_us * (guess.pds_us - lagged.pds_us) / guess.pds_us

        -- [12.39] expected real disposable income in UK
        ydhse_k_uk =
            (ydhs_k_uk + lagged.ydhs_k_uk) / 2

        -- [12.40] expected real disposable income in US
        ydhse_k_us =
            (ydhs_k_us + lagged.ydhs_k_us) / 2

        -- [12.37] real consumption in UK
        c_k_uk =
            (params.alpha1_uk - params.zeta_uk * (params.r_uk - (lagged.gpi_uk - 1) - params.rstar_uk)) * ydhse_k_uk + params.alpha2_uk * lagged.v_k_uk

        -- [12.38] real consumption in US
        c_k_us =
            params.alpha1_us * ydhse_k_us + params.alpha2_us * lagged.v_k_us

        -- [12.41] real sales in UK
        s_k_uk =
            c_k_uk + params.g_k_uk + x_k_uk

        -- [12.42] real sales in US
        s_k_us =
            c_k_us + params.g_k_us + x_k_us

        -- [12.55] real output in UK
        y_k_uk =
            s_k_uk - im_k_uk

        -- [12.56] real output in US
        y_k_us =
            s_k_us - im_k_us

        -- [12.65] employment in UK
        n_uk =
            y_k_uk / params.pr_uk

        -- unemployment rate in UK, against a labour force that grows with the trend (not in the book)
        u_uk =
            1 - n_uk / params.lf_uk

        -- [12.66] employment in US
        n_us =
            y_k_us / params.pr_us

        -- comparison with the starting path, where the wage is w_uk and the price level pref_uk.
        wage_uk =
            params.w_uk * exp ((1 - params.wspeed_uk) * ln (lagged.wage_uk * params.infl_uk / params.w_uk) + params.wspeed_uk * (params.kappa_uk * ln (lagged.pds_uk * params.infl_uk / params.pref_uk) + params.beta_uk * (lagged.u_uk - params.ustar_uk) / params.ustar_uk))

        -- [12.45] price of sales in UK
        ps_uk =
            (1 + params.phi_uk) * (wage_uk * n_uk + im_uk) / s_k_uk

        -- [12.46] price of sales in US
        ps_us =
            (1 + params.phi_us) * (params.w_us * n_us + im_us) / s_k_us

        -- [12.43] value of sales in UK
        s_uk =
            s_k_uk * ps_uk

        -- [12.44] value of sales in US
        s_us =
            s_k_us * ps_us

        -- [12.47] price of domestic sales in UK
        pds_uk =
            (s_uk - x_uk) / (s_k_uk - x_k_uk)

        -- [12.48] price of domestic sales in US
        pds_us =
            (s_us - x_us) / (s_k_us - x_k_us)

        -- [12.53] value of output in UK
        y_uk =
            s_uk - im_uk

        -- [12.54] value of output in US
        y_us =
            s_us - im_us

        -- [12.57] price of output in UK
        py_uk =
            y_uk / y_k_uk

        -- [12.58] price of output in US
        py_us =
            y_us / y_k_us

        -- [12.59] consumption in UK
        cons_uk =
            c_k_uk * pds_uk

        -- [12.60] consumption in US
        cons_us =
            c_k_us * pds_us

        -- [12.61] government expenditure in UK
        g_uk =
            params.g_k_uk * pds_uk

        -- [12.62] government expenditure in US
        g_us =
            params.g_k_us * pds_us

        -- foreign direct investment into the UK: what foreigners pay UK households for a share of UK firms (not in the book)
        fdi_in_uk =
            params.fdi_flow_uk * y_uk

        -- the stock of UK firms owned abroad
        fdi_uk =
            lagged.fdi_uk + fdi_in_uk

        -- UK inflation in the period, gross and per period, trend included (not in the book)
        gpi_uk =
            pds_uk / lagged.pds_uk

        -- [12.3] wealth accumulation in UK, plus the proceeds of direct investment
        v_uk =
            lagged.v_uk + yd_uk - cons_uk + fdi_in_uk

        -- [12.6] wealth accumulation in US
        v_us =
            lagged.v_us + yd_us - cons_us - fdi_in_uk * guess.xr_uk

        -- [12.33] real wealth in UK
        v_k_uk =
            v_uk / pds_uk

        -- [12.34] real wealth in US
        v_k_us =
            v_us / pds_us

        -- [12.11] profits of the central bank in UK
        f_cb_uk =
            laggedParams.r_uk * lagged.b_cb_ukuk_d + laggedParams.r_us * laggedParams.b_cb_ukus_s / (params.trend * params.infl_us) * xr_us

        -- [12.12] profits of the central bank in US
        f_cb_us =
            laggedParams.r_us * lagged.b_cb_usus_d

        -- [12.13] government budget constraint in UK
        b_uk_s =
            lagged.b_uk_s + g_uk + tr_uk + laggedParams.r_uk * lagged.b_uk_s - t_uk - f_cb_uk

        -- [12.14] government budget constraint in US
        b_us_s =
            lagged.b_us_s + g_us + laggedParams.r_us * lagged.b_us_s - t_us - f_cb_us

        -- [12.67] demand for UK bills in UK
        b_ukuk_d =
            v_uk * (params.lambda10 + params.lambda11 * params.r_uk - params.lambda12 * (params.r_us + params.dxre_us))

        -- [12.68] demand for US bills in UK
        b_ukus_d =
            v_uk * (params.lambda20 - params.lambda21 * params.r_uk + params.lambda22 * (params.r_us + params.dxre_us))

        -- [12.69] demand for money in UK
        h_uk_d =
            v_uk - b_ukuk_d - b_ukus_d

        -- [12.70] demand for US bills in US
        b_usus_d =
            v_us * (params.lambda40 + params.lambda41 * params.r_us - params.lambda42 * (params.r_uk + params.dxre_uk))

        -- [12.71] demand for UK bills in US
        b_usuk_d =
            v_us * (params.lambda50 - params.lambda51 * params.r_us + params.lambda52 * (params.r_uk + params.dxre_uk))

        -- [12.72] demand for money in US
        h_us_d =
            v_us - b_usus_d - b_usuk_d

        -- [12.83] balance sheet of the US central bank, in changes (gold left out)
        b_cb_usus_d =
            lagged.b_cb_usus_d + (h_us_d - lagged.h_us_d)

        -- [12.87] UK bills acquired by US households
        b_usuk_s =
            b_usuk_d * xr_us

        -- [12.82A] the UK central bank takes the UK bills nobody else holds
        b_cb_ukuk_d =
            b_uk_s - b_ukuk_d - b_usuk_s

        -- [12.90] US bills left for UK households
        b_ukus_s =
            b_us_s - b_usus_d - b_cb_usus_d - params.b_cb_ukus_s

        -- [12.15] current account balance of UK
        cab_uk =
            x_uk - im_uk + xr_us * laggedParams.r_us * lagged.b_ukus_s - laggedParams.r_uk * lagged.b_usuk_s + laggedParams.r_us * laggedParams.b_cb_ukus_s / (params.trend * params.infl_us) * xr_us - remit_uk

        -- government deficit in UK
        psbr_uk =
            g_uk + tr_uk + laggedParams.r_uk * lagged.b_uk_s - t_uk - f_cb_uk

        -- government deficit in US
        psbr_us =
            g_us + laggedParams.r_us * lagged.b_us_s - t_us - f_cb_us

        -- [12.89FL] the exchange rate clears the market for US bills held in the UK
        xr_uk =
            b_ukus_s / b_ukus_d
    in
    { xr_us = xr_us
    , pm_uk = pm_uk
    , px_uk = px_uk
    , px_us = px_us
    , pm_us = pm_us
    , x_k_uk = x_k_uk
    , im_k_uk = im_k_uk
    , x_k_us = x_k_us
    , im_k_us = im_k_us
    , x_uk = x_uk
    , x_us = x_us
    , im_uk = im_uk
    , im_us = im_us
    , remit_uk = remit_uk
    , t_uk = t_uk
    , t_us = t_us
    , tr_uk = tr_uk
    , yd_uk = yd_uk
    , yd_us = yd_us
    , ydhs_k_uk = ydhs_k_uk
    , ydhs_k_us = ydhs_k_us
    , ydhse_k_uk = ydhse_k_uk
    , ydhse_k_us = ydhse_k_us
    , c_k_uk = c_k_uk
    , c_k_us = c_k_us
    , s_k_uk = s_k_uk
    , s_k_us = s_k_us
    , y_k_uk = y_k_uk
    , y_k_us = y_k_us
    , n_uk = n_uk
    , u_uk = u_uk
    , n_us = n_us
    , wage_uk = wage_uk
    , ps_uk = ps_uk
    , ps_us = ps_us
    , s_uk = s_uk
    , s_us = s_us
    , pds_uk = pds_uk
    , pds_us = pds_us
    , y_uk = y_uk
    , y_us = y_us
    , py_uk = py_uk
    , py_us = py_us
    , cons_uk = cons_uk
    , cons_us = cons_us
    , g_uk = g_uk
    , g_us = g_us
    , fdi_in_uk = fdi_in_uk
    , fdi_uk = fdi_uk
    , gpi_uk = gpi_uk
    , v_uk = v_uk
    , v_us = v_us
    , v_k_uk = v_k_uk
    , v_k_us = v_k_us
    , f_cb_uk = f_cb_uk
    , f_cb_us = f_cb_us
    , b_uk_s = b_uk_s
    , b_us_s = b_us_s
    , b_ukuk_d = b_ukuk_d
    , b_ukus_d = b_ukus_d
    , h_uk_d = h_uk_d
    , b_usus_d = b_usus_d
    , b_usuk_d = b_usuk_d
    , h_us_d = h_us_d
    , b_cb_usus_d = b_cb_usus_d
    , b_usuk_s = b_usuk_s
    , b_cb_ukuk_d = b_cb_ukuk_d
    , b_ukus_s = b_ukus_s
    , cab_uk = cab_uk
    , psbr_uk = psbr_uk
    , psbr_us = psbr_us
    , xr_uk = xr_uk
    }


relativeChange : Float -> Float -> Float
relativeChange before after =
    abs (after - before) / max 1 (abs before)


worst : Float -> Float -> Float
worst term soFar =
    if isNaN term || isNaN soFar then
        0 / 0

    else
        max term soFar


{-| The largest relative change in any variable between two passes.
-}
distance : Vars -> Vars -> Float
distance before after =
    List.foldl worst
        0
        [ relativeChange before.xr_us after.xr_us
        , relativeChange before.pm_uk after.pm_uk
        , relativeChange before.px_uk after.px_uk
        , relativeChange before.px_us after.px_us
        , relativeChange before.pm_us after.pm_us
        , relativeChange before.x_k_uk after.x_k_uk
        , relativeChange before.im_k_uk after.im_k_uk
        , relativeChange before.x_k_us after.x_k_us
        , relativeChange before.im_k_us after.im_k_us
        , relativeChange before.x_uk after.x_uk
        , relativeChange before.x_us after.x_us
        , relativeChange before.im_uk after.im_uk
        , relativeChange before.im_us after.im_us
        , relativeChange before.remit_uk after.remit_uk
        , relativeChange before.t_uk after.t_uk
        , relativeChange before.t_us after.t_us
        , relativeChange before.tr_uk after.tr_uk
        , relativeChange before.yd_uk after.yd_uk
        , relativeChange before.yd_us after.yd_us
        , relativeChange before.ydhs_k_uk after.ydhs_k_uk
        , relativeChange before.ydhs_k_us after.ydhs_k_us
        , relativeChange before.ydhse_k_uk after.ydhse_k_uk
        , relativeChange before.ydhse_k_us after.ydhse_k_us
        , relativeChange before.c_k_uk after.c_k_uk
        , relativeChange before.c_k_us after.c_k_us
        , relativeChange before.s_k_uk after.s_k_uk
        , relativeChange before.s_k_us after.s_k_us
        , relativeChange before.y_k_uk after.y_k_uk
        , relativeChange before.y_k_us after.y_k_us
        , relativeChange before.n_uk after.n_uk
        , relativeChange before.u_uk after.u_uk
        , relativeChange before.n_us after.n_us
        , relativeChange before.wage_uk after.wage_uk
        , relativeChange before.ps_uk after.ps_uk
        , relativeChange before.ps_us after.ps_us
        , relativeChange before.s_uk after.s_uk
        , relativeChange before.s_us after.s_us
        , relativeChange before.pds_uk after.pds_uk
        , relativeChange before.pds_us after.pds_us
        , relativeChange before.y_uk after.y_uk
        , relativeChange before.y_us after.y_us
        , relativeChange before.py_uk after.py_uk
        , relativeChange before.py_us after.py_us
        , relativeChange before.cons_uk after.cons_uk
        , relativeChange before.cons_us after.cons_us
        , relativeChange before.g_uk after.g_uk
        , relativeChange before.g_us after.g_us
        , relativeChange before.fdi_in_uk after.fdi_in_uk
        , relativeChange before.fdi_uk after.fdi_uk
        , relativeChange before.gpi_uk after.gpi_uk
        , relativeChange before.v_uk after.v_uk
        , relativeChange before.v_us after.v_us
        , relativeChange before.v_k_uk after.v_k_uk
        , relativeChange before.v_k_us after.v_k_us
        , relativeChange before.f_cb_uk after.f_cb_uk
        , relativeChange before.f_cb_us after.f_cb_us
        , relativeChange before.b_uk_s after.b_uk_s
        , relativeChange before.b_us_s after.b_us_s
        , relativeChange before.b_ukuk_d after.b_ukuk_d
        , relativeChange before.b_ukus_d after.b_ukus_d
        , relativeChange before.h_uk_d after.h_uk_d
        , relativeChange before.b_usus_d after.b_usus_d
        , relativeChange before.b_usuk_d after.b_usuk_d
        , relativeChange before.h_us_d after.h_us_d
        , relativeChange before.b_cb_usus_d after.b_cb_usus_d
        , relativeChange before.b_usuk_s after.b_usuk_s
        , relativeChange before.b_cb_ukuk_d after.b_cb_ukuk_d
        , relativeChange before.b_ukus_s after.b_ukus_s
        , relativeChange before.cab_uk after.cab_uk
        , relativeChange before.psbr_uk after.psbr_uk
        , relativeChange before.psbr_us after.psbr_us
        , relativeChange before.xr_uk after.xr_uk
        ]



-- SOLVING


{-| Solve one period, given the previous period and the parameters then and
now. Fails, rather than returning nonsense, when the passes do not settle.
-}
step : Params -> Vars -> Params -> Result Solver.Error Vars
step laggedParams lagged params =
    Solver.fixedPoint
        { sweep = sweep laggedParams (carry params lagged) params
        , distance = distance
        , tolerance = 1.0e-12
        , maxSweeps = 500
        }
        lagged


type alias Failure =
    { period : Int
    , error : Solver.Error
    }


{-| Run a number of periods from the steady state. `paramsAt` gives the
parameters in force in each period; period 0 is the period before the first.
-}
simulate : (Int -> Params) -> Int -> Result Failure (List Vars)
simulate paramsAt periods =
    simulateFrom paramsAt periods 1 steadyState []


simulateFrom : (Int -> Params) -> Int -> Int -> Vars -> List Vars -> Result Failure (List Vars)
simulateFrom paramsAt periods period lagged solved =
    if period > periods then
        Ok (List.reverse solved)

    else
        case step (paramsAt (period - 1)) lagged (paramsAt period) of
            Ok vars ->
                simulateFrom paramsAt periods (period + 1) vars (vars :: solved)

            Err error ->
                Err { period = period, error = error }



-- TRANSACTION FLOWS


sectors : List Sector
sectors =
    [ Households, Firms, Government, CentralBank, RestOfWorld ]


{-| The home country's payments in a period, in its own currency, with the
foreign country as a single sector. Capital gains from the exchange rate are
not payments, so they do not appear: foreign bills enter at what was paid for
them in the period. `lagged` is the previous period as `carry` returns it.
-}
flows : Params -> Vars -> Params -> Vars -> List Flow
flows laggedParams lagged params vars =
    [ Flow "Consumo" Households Firms vars.cons_uk
    , Flow "Gasto público" Government Firms vars.g_uk
    , Flow "Exportações" RestOfWorld Firms vars.x_uk
    , Flow "Importações" Firms RestOfWorld vars.im_uk
    , Flow "Renda" Firms Households (vars.y_uk - vars.remit_uk)
    , Flow "Lucros remetidos ao exterior" Firms RestOfWorld vars.remit_uk
    , Flow "Investimento direto recebido" RestOfWorld Households vars.fdi_in_uk
    , Flow "Impostos" Households Government vars.t_uk
    , Flow "Transferências" Government Households vars.tr_uk
    , Flow "Juros dos títulos domésticos das famílias" Government Households (laggedParams.r_uk * lagged.b_ukuk_d)
    , Flow "Juros dos títulos domésticos do banco central" Government CentralBank (laggedParams.r_uk * lagged.b_cb_ukuk_d)
    , Flow "Juros dos títulos domésticos do exterior" Government RestOfWorld (laggedParams.r_uk * lagged.b_usuk_s)
    , Flow "Juros dos títulos estrangeiros das famílias" RestOfWorld Households (vars.xr_us * laggedParams.r_us * lagged.b_ukus_s)
    , Flow "Juros dos títulos estrangeiros do banco central" RestOfWorld CentralBank (vars.xr_us * laggedParams.r_us * laggedParams.b_cb_ukus_s / (params.trend * params.infl_us))
    , Flow "Lucro do banco central" CentralBank Government vars.f_cb_uk
    , Flow "Variação do dinheiro" Households CentralBank (vars.h_uk_d - lagged.h_uk_d)
    , Flow "Variação dos títulos domésticos das famílias" Households Government (vars.b_ukuk_d - lagged.b_ukuk_d)
    , Flow "Variação dos títulos domésticos do banco central" CentralBank Government (vars.b_cb_ukuk_d - lagged.b_cb_ukuk_d)
    , Flow "Variação dos títulos domésticos do exterior" RestOfWorld Government (vars.b_usuk_s - lagged.b_usuk_s)
    , Flow "Variação dos títulos estrangeiros das famílias" Households RestOfWorld ((vars.b_ukus_s - lagged.b_ukus_s) * vars.xr_us)
    , Flow "Variação dos títulos estrangeiros do banco central" CentralBank RestOfWorld ((params.b_cb_ukus_s - laggedParams.b_cb_ukus_s / (params.trend * params.infl_us)) * vars.xr_us)
    ]
