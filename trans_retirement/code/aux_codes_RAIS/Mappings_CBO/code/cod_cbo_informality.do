/******************************************************************************
						Translate COD (PNAD-C) to CBO (RAIS) and
						calculate share of informality for each 
						4-digit occupation
					
******************************************************************************

Creation date: 20/09/2024
Last Update:   
Input:         $\data\pnadc\output\pnadcontinua_trimestral\pnadcontinua\
			   
Output: 	   $COD_CBO_share_informality.dta
			
******************************************************************************/

clear all 
set more off
capture log close

gl pnadc "F:/data/pnadc/output/pnadcontinua_trimestral/pnadcontinua" 
gl path  "F:/Users/Isabella/RA/Mappings RAIS/"


/////////////////////////////////////////////////////////////////
// STEP 1 - Share of informality                               //
/////////////////////////////////////////////////////////////////


cd "$pnadc"

use PNADC_trimestral_2012.dta, clear

foreach i in 2013 2014 2015 2016 2017 2018 2019{

append using PNADC_trimestral_`i'.dta

keep Ano Trimestre V1028 V2007 V2009 V4010 V4013 V4029 VD4009 V4019 VD4002

}

gen aux      =1 if VD4002==1 & V2009>=14
replace aux  =2 if VD4002==2 & V2009>=14
replace aux  =3 if VD4002==. & V2009>=14

tab aux, gen(s)

ren s1 ocupados
ren s2 desocup
ren s3 inativo


gen pos_ocup    =.
replace pos_ocup=1 if (VD4009==1 | VD4009==3 | VD4009==5)
replace pos_ocup=2 if (VD4009==2 | VD4009==4 | VD4009==6)
replace pos_ocup=3 if VD4009==7
replace pos_ocup=4 if VD4009==8
replace pos_ocup=5 if VD4009==9
replace pos_ocup=6 if VD4009==10

tab pos_ocup, gen(s)

rename s1 com_cart 
rename s2 sem_cart 
rename s3 militar_estat
rename s4 empregador 
rename s5 conta_propria
rename s6 nao_rem  

gen cnpj=cond(V4019==1,1,0) if V4019!=.

*INFORMALIDADE: trabalhadores sem carteira + conta-propria s/CNPJ + empregador s/CNPJ + nao remunerados)/ocupados

gen informal    =0 if aux==1 
replace informal=1 if [sem_cart==1 | nao_rem==1 | (conta_propria==1 & cnpj==0) | (empregador==1 & cnpj==0)]

ren V4010 cod

gcollapse (mean) informal [iw=V1028], by(cod)

drop if cod==.

/////////////////////////////////////////////////////////////////
// STEP 2 - COD to CBO                                         //
/////////////////////////////////////////////////////////////////

						
gen	cbo	=	.				
replace	cbo	=	1111	if	cod	==	1111
replace	cbo	=	1114	if	cod	==	1112
replace	cbo	=	1112	if	cod	==	1112 
replace	cbo	=	1130	if	cod	==	1113
replace	cbo	=	1144	if	cod	==	1114
replace	cbo	=	1210	if	cod	==	1120
replace	cbo	=	1231	if	cod	==	1211
replace	cbo	=	1421	if	cod	==	1211 
replace	cbo	=	1232	if	cod	==	1212
replace	cbo	=	1234	if	cod	==	1213
replace	cbo	=	1237	if	cod	==	1219
replace	cbo	=	1233	if	cod	==	1221
replace	cbo	=	1423	if	cod	==	1222
replace	cbo	=	1237	if	cod	==	1223
replace	cbo	=	1221	if	cod	==	1311
replace	cbo	=	1221	if	cod	==	1312
replace	cbo	=	1222	if	cod	==	1321
replace	cbo	=	1222	if	cod	==	1322
replace	cbo	=	1223	if	cod	==	1323
replace	cbo	=	1416	if	cod	==	1324
replace	cbo	=	1236	if	cod	==	1330
replace	cbo	=	1311	if	cod	==	1341
replace	cbo	=	1312	if	cod	==	1342
replace	cbo	=	1311	if	cod	==	1343
replace	cbo	=	1311	if	cod	==	1344
replace	cbo	=	1313	if	cod	==	1345
replace	cbo	=	1417	if	cod	==	1346
replace	cbo	=	1313	if	cod	==	1349
replace	cbo	=	1415	if	cod	==	1411
replace	cbo	=	1415	if	cod	==	1412
replace	cbo	=	1224	if	cod	==	1420
replace	cbo	=	1311	if	cod	==	1431
replace	cbo	=	1414	if	cod	==	1439
replace	cbo	=	2131	if	cod	==	2111
replace	cbo	=	2133	if	cod	==	2112
replace	cbo	=	2132	if	cod	==	2113
replace	cbo	=	2134	if	cod	==	2114
replace	cbo	=	2111	if	cod	==	2120
replace	cbo	=	2211	if	cod	==	2131
replace	cbo	=	2222	if	cod	==	2132
replace	cbo	=	2040	if	cod	==	2133
replace	cbo	=	2149	if	cod	==	2141
replace	cbo	=	2142	if	cod	==	2142
replace	cbo	=	2140	if	cod	==	2143
replace	cbo	=	2144	if	cod	==	2144
replace	cbo	=	2145	if	cod	==	2145
replace	cbo	=	2146	if	cod	==	2146
replace	cbo	=	2142	if	cod	==	2149
replace	cbo	=	2143	if	cod	==	2151
replace	cbo	=	2143	if	cod	==	2152
replace	cbo	=	2143	if	cod	==	2153
replace	cbo	=	2141	if	cod	==	2161
replace	cbo	=	2141	if	cod	==	2162
replace	cbo	=	3751	if	cod	==	2163
replace	cbo	=	2141	if	cod	==	2164
replace	cbo	=	2148	if	cod	==	2165
replace	cbo	=	2624	if	cod	==	2166
replace	cbo	=	2231	if	cod	==	2211
replace	cbo	=	2231	if	cod	==	2212
replace	cbo	=	2235	if	cod	==	2221
replace	cbo	=	2235	if	cod	==	2222
replace	cbo	=	3221	if	cod	==	2230
replace	cbo	=	2235	if	cod	==	2240
replace	cbo	=	2233	if	cod	==	2250
replace	cbo	=	2232	if	cod	==	2261
replace	cbo	=	2234	if	cod	==	2262
replace	cbo	=	2239	if	cod	==	2263
replace	cbo	=	2236	if	cod	==	2264
replace	cbo	=	2237	if	cod	==	2265
replace	cbo	=	2238	if	cod	==	2266
replace	cbo	=	3221	if	cod	==	2267
replace	cbo	=	2235	if	cod	==	2269
replace	cbo	=	2341	if	cod	==	2310
replace	cbo	=	2331	if	cod	==	2320
replace	cbo	=	2321	if	cod	==	2330
replace	cbo	=	2312	if	cod	==	2341
replace	cbo	=	2311	if	cod	==	2342
replace	cbo	=	2394	if	cod	==	2351
replace	cbo	=	2392	if	cod	==	2352
replace	cbo	=	2346	if	cod	==	2353
replace	cbo	=	2349	if	cod	==	2354
replace	cbo	=	2349	if	cod	==	2355
replace	cbo	=	2332	if	cod	==	2356
replace	cbo	=	2394	if	cod	==	2359
replace	cbo	=	2522	if	cod	==	2411
replace	cbo	=	2525	if	cod	==	2412
replace	cbo	=	2525	if	cod	==	2413
replace	cbo	=	2521	if	cod	==	2421
replace	cbo	=	2521	if	cod	==	2422
replace	cbo	=	2524	if	cod	==	2423
replace	cbo	=	2524	if	cod	==	2424
replace	cbo	=	2531	if	cod	==	2431
replace	cbo	=	2531	if	cod	==	2432
replace	cbo	=	3541	if	cod	==	2433
replace	cbo	=	3541	if	cod	==	2434
replace	cbo	=	2124	if	cod	==	2511
replace	cbo	=	2124	if	cod	==	2512
replace	cbo	=	2124	if	cod	==	2513
replace	cbo	=	2124	if	cod	==	2514
replace	cbo	=	2124	if	cod	==	2519
replace	cbo	=	2124	if	cod	==	2521
replace	cbo	=	2123	if	cod	==	2522
replace	cbo	=	2123	if	cod	==	2523
replace	cbo	=	2123	if	cod	==	2529
replace	cbo	=	2410	if	cod	==	2611
replace	cbo	=	1113	if	cod	==	2612
replace	cbo	=	2412	if	cod	==	2619
replace	cbo	=	2613	if	cod	==	2621
replace	cbo	=	2612	if	cod	==	2622
replace	cbo	=	2512	if	cod	==	2631
replace	cbo	=	2511	if	cod	==	2632
replace	cbo	=	2514	if	cod	==	2633
replace	cbo	=	2515	if	cod	==	2634
replace	cbo	=	2516	if	cod	==	2635
replace	cbo	=	2631	if	cod	==	2636
replace	cbo	=	2615	if	cod	==	2641
replace	cbo	=	2611	if	cod	==	2642
replace	cbo	=	2614	if	cod	==	2643
replace	cbo	=	2624	if	cod	==	2651
replace	cbo	=	2626	if	cod	==	2652
replace	cbo	=	2628	if	cod	==	2653
replace	cbo	=	2622	if	cod	==	2654
replace	cbo	=	2625	if	cod	==	2655
replace	cbo	=	2617	if	cod	==	2656
replace	cbo	=	2623	if	cod	==	2659
replace	cbo	=	3111	if	cod	==	3111
replace	cbo	=	3121	if	cod	==	3112
replace	cbo	=	3131	if	cod	==	3113
replace	cbo	=	3132	if	cod	==	3114
replace	cbo	=	3141	if	cod	==	3115
replace	cbo	=	3112	if	cod	==	3116
replace	cbo	=	3163	if	cod	==	3117
replace	cbo	=	3180	if	cod	==	3118
replace	cbo	=	3116	if	cod	==	3119
replace	cbo	=	7101	if	cod	==	3121
replace	cbo	=	8102	if	cod	==	3122
replace	cbo	=	7102	if	cod	==	3123
replace	cbo	=	8611	if	cod	==	3131
replace	cbo	=	8622	if	cod	==	3132
replace	cbo	=	8112	if	cod	==	3133
replace	cbo	=	8115	if	cod	==	3134
replace	cbo	=	8213	if	cod	==	3135
replace	cbo	=	8214	if	cod	==	3139
replace	cbo	=	3201	if	cod	==	3141
replace	cbo	=	3211	if	cod	==	3142
replace	cbo	=	3212	if	cod	==	3143
replace	cbo	=	2152	if	cod	==	3151
replace	cbo	=	2151	if	cod	==	3152
replace	cbo	=	2153	if	cod	==	3153
replace	cbo	=	3425	if	cod	==	3154
replace	cbo	=	3411	if	cod	==	3155
replace	cbo	=	3241	if	cod	==	3211
replace	cbo	=	3242	if	cod	==	3212
replace	cbo	=	3251	if	cod	==	3213
replace	cbo	=	3224	if	cod	==	3214
replace	cbo	=	3222	if	cod	==	3221
replace	cbo	=	3222	if	cod	==	3222
replace	cbo	=	3221	if	cod	==	3230
replace	cbo	=	3231	if	cod	==	3240
replace	cbo	=	3224	if	cod	==	3251
replace	cbo	=	4151	if	cod	==	3252
replace	cbo	=	3522	if	cod	==	3253
replace	cbo	=	3223	if	cod	==	3254
replace	cbo	=	3221	if	cod	==	3255
replace	cbo	=	3222	if	cod	==	3256
replace	cbo	=	3516	if	cod	==	3257
replace	cbo	=	5151	if	cod	==	3258
replace	cbo	=	3222	if	cod	==	3259
replace	cbo	=	3532	if	cod	==	3311
replace	cbo	=	3532	if	cod	==	3312
replace	cbo	=	3511	if	cod	==	3313
replace	cbo	=	4241	if	cod	==	3314
replace	cbo	=	3544	if	cod	==	3315
replace	cbo	=	3545	if	cod	==	3321
replace	cbo	=	3541	if	cod	==	3322
replace	cbo	=	3542	if	cod	==	3323
replace	cbo	=	3547	if	cod	==	3324
replace	cbo	=	3422	if	cod	==	3331
replace	cbo	=	3548	if	cod	==	3332
replace	cbo	=	3513	if	cod	==	3333
replace	cbo	=	3546	if	cod	==	3334
replace	cbo	=	3543	if	cod	==	3339
replace	cbo	=	4101	if	cod	==	3341
replace	cbo	=	3514	if	cod	==	3342
replace	cbo	=	3515	if	cod	==	3343
replace	cbo	=	3515	if	cod	==	3344
replace	cbo	=	3422	if	cod	==	3351
replace	cbo	=	3511	if	cod	==	3352
replace	cbo	=	3517	if	cod	==	3353
replace	cbo	=	3522	if	cod	==	3354
replace	cbo	=	3518	if	cod	==	3355
replace	cbo	=	3523	if	cod	==	3359
replace	cbo	=	3514	if	cod	==	3411
replace	cbo	=	3522	if	cod	==	3412
replace	cbo	=	5141	if	cod	==	3413
replace	cbo	=	3771	if	cod	==	3421
replace	cbo	=	3772	if	cod	==	3422
replace	cbo	=	3714	if	cod	==	3423
replace	cbo	=	2618	if	cod	==	3431
replace	cbo	=	3751	if	cod	==	3432
replace	cbo	=	3751	if	cod	==	3433
replace	cbo	=	2711	if	cod	==	3434
replace	cbo	=	3761	if	cod	==	3435
replace	cbo	=	3133	if	cod	==	3511
replace	cbo	=	3172	if	cod	==	3512
replace	cbo	=	3171	if	cod	==	3513
replace	cbo	=	3171	if	cod	==	3514
replace	cbo	=	3731	if	cod	==	3521
replace	cbo	=	3133	if	cod	==	3522
replace	cbo	=	4110	if	cod	==	4110
replace	cbo	=	3515	if	cod	==	4120
replace	cbo	=	4121	if	cod	==	4131
replace	cbo	=	4121	if	cod	==	4132
replace	cbo	=	4132	if	cod	==	4211
replace	cbo	=	4212	if	cod	==	4212
replace	cbo	=	4211	if	cod	==	4213
replace	cbo	=	4213	if	cod	==	4214
replace	cbo	=	3548	if	cod	==	4221
replace	cbo	=	4221	if	cod	==	4222
replace	cbo	=	4222	if	cod	==	4223
replace	cbo	=	4221	if	cod	==	4224
replace	cbo	=	4221	if	cod	==	4225
replace	cbo	=	4221	if	cod	==	4226
replace	cbo	=	4241	if	cod	==	4227
replace	cbo	=	4223	if	cod	==	4229
replace	cbo	=	4131	if	cod	==	4311
replace	cbo	=	4110	if	cod	==	4312
replace	cbo	=	4131	if	cod	==	4313
replace	cbo	=	4141	if	cod	==	4321
replace	cbo	=	4142	if	cod	==	4322
replace	cbo	=	3421	if	cod	==	4323
replace	cbo	=	4151	if	cod	==	4411
replace	cbo	=	4152	if	cod	==	4412
replace	cbo	=	4121	if	cod	==	4413
replace	cbo	=	4151	if	cod	==	4414
replace	cbo	=	4151	if	cod	==	4415
replace	cbo	=	4122	if	cod	==	4416
replace	cbo	=	4122	if	cod	==	4419
replace	cbo	=	5111	if	cod	==	5111
replace	cbo	=	5112	if	cod	==	5112
replace	cbo	=	5114	if	cod	==	5113
replace	cbo	=	5132	if	cod	==	5120
replace	cbo	=	5134	if	cod	==	5131
replace	cbo	=	5134	if	cod	==	5132
replace	cbo	=	5161	if	cod	==	5141
replace	cbo	=	5161	if	cod	==	5142
replace	cbo	=	5101	if	cod	==	5151
replace	cbo	=	5131	if	cod	==	5152
replace	cbo	=	5141	if	cod	==	5153
replace	cbo	=	5167	if	cod	==	5161
replace	cbo	=	5162	if	cod	==	5162
replace	cbo	=	5165	if	cod	==	5163
replace	cbo	=	6230	if	cod	==	5164
replace	cbo	=	3331	if	cod	==	5165
replace	cbo	=	5198	if	cod	==	5168
replace	cbo	=	5163	if	cod	==	5169
replace	cbo	=	5242	if	cod	==	5211
replace	cbo	=	5243	if	cod	==	5212
replace	cbo	=	1414	if	cod	==	5221
replace	cbo	=	5201	if	cod	==	5222
replace	cbo	=	5211	if	cod	==	5223
replace	cbo	=	4211	if	cod	==	5230
replace	cbo	=	3764	if	cod	==	5241
replace	cbo	=	5211	if	cod	==	5242
replace	cbo	=	5241	if	cod	==	5243
replace	cbo	=	4223	if	cod	==	5244
replace	cbo	=	5211	if	cod	==	5245
replace	cbo	=	5211	if	cod	==	5246
replace	cbo	=	5211	if	cod	==	5249
replace	cbo	=	5162	if	cod	==	5311
replace	cbo	=	5162	if	cod	==	5312
replace	cbo	=	5153	if	cod	==	5321
replace	cbo	=	5162	if	cod	==	5322
replace	cbo	=	5151	if	cod	==	5329
replace	cbo	=	5171	if	cod	==	5411
replace	cbo	=	5172	if	cod	==	5412
replace	cbo	=	5173	if	cod	==	5413
replace	cbo	=	5173	if	cod	==	5414
replace	cbo	=	5174	if	cod	==	5419
replace	cbo	=	6210	if	cod	==	6111
replace	cbo	=	6224	if	cod	==	6112
replace	cbo	=	6221	if	cod	==	6114
replace	cbo	=	6231	if	cod	==	6121
replace	cbo	=	6233	if	cod	==	6122
replace	cbo	=	6234	if	cod	==	6123
replace	cbo	=	6231	if	cod	==	6129
replace	cbo	=	6110	if	cod	==	6130
replace	cbo	=	6320	if	cod	==	6210
replace	cbo	=	6313	if	cod	==	6221
replace	cbo	=	6310	if	cod	==	6224
replace	cbo	=	6310	if	cod	==	6225
replace	cbo	=	7102	if	cod	==	7111
replace	cbo	=	7152	if	cod	==	7112
replace	cbo	=	7122	if	cod	==	7113
replace	cbo	=	7153	if	cod	==	7114
replace	cbo	=	7155	if	cod	==	7115
replace	cbo	=	7151	if	cod	==	7119
replace	cbo	=	7162	if	cod	==	7121
replace	cbo	=	7165	if	cod	==	7122
replace	cbo	=	7164	if	cod	==	7123
replace	cbo	=	7157	if	cod	==	7124
replace	cbo	=	7163	if	cod	==	7125
replace	cbo	=	7241	if	cod	==	7126
replace	cbo	=	7257	if	cod	==	7127
replace	cbo	=	7166	if	cod	==	7131
replace	cbo	=	7165	if	cod	==	7132
replace	cbo	=	5143	if	cod	==	7133
replace	cbo	=	7223	if	cod	==	7211
replace	cbo	=	7243	if	cod	==	7212
replace	cbo	=	7244	if	cod	==	7213
replace	cbo	=	7242	if	cod	==	7214
replace	cbo	=	7246	if	cod	==	7215
replace	cbo	=	7221	if	cod	==	7221
replace	cbo	=	7211	if	cod	==	7222
replace	cbo	=	7212	if	cod	==	7223
replace	cbo	=	7213	if	cod	==	7224
replace	cbo	=	9144	if	cod	==	7231
replace	cbo	=	9141	if	cod	==	7232
replace	cbo	=	9131	if	cod	==	7233
replace	cbo	=	9193	if	cod	==	7234
replace	cbo	=	7411	if	cod	==	7311
replace	cbo	=	7421	if	cod	==	7312
replace	cbo	=	7510	if	cod	==	7313
replace	cbo	=	7523	if	cod	==	7314
replace	cbo	=	7522	if	cod	==	7315
replace	cbo	=	7122	if	cod	==	7316
replace	cbo	=	7122	if	cod	==	7317
replace	cbo	=	7683	if	cod	==	7318
replace	cbo	=	7681	if	cod	==	7319
replace	cbo	=	7661	if	cod	==	7321
replace	cbo	=	7662	if	cod	==	7322
replace	cbo	=	7687	if	cod	==	7323
replace	cbo	=	7156	if	cod	==	7411
replace	cbo	=	9511	if	cod	==	7412
replace	cbo	=	7321	if	cod	==	7413
replace	cbo	=	9511	if	cod	==	7421
replace	cbo	=	7313	if	cod	==	7422
replace	cbo	=	8485	if	cod	==	7511
replace	cbo	=	8483	if	cod	==	7512
replace	cbo	=	8482	if	cod	==	7513
replace	cbo	=	8481	if	cod	==	7514
replace	cbo	=	8484	if	cod	==	7515
replace	cbo	=	8486	if	cod	==	7516
replace	cbo	=	7721	if	cod	==	7521
replace	cbo	=	7711	if	cod	==	7522
replace	cbo	=	7731	if	cod	==	7523
replace	cbo	=	7630	if	cod	==	7531
replace	cbo	=	7631	if	cod	==	7532
replace	cbo	=	7682	if	cod	==	7533
replace	cbo	=	7652	if	cod	==	7534
replace	cbo	=	7621	if	cod	==	7535
replace	cbo	=	7683	if	cod	==	7536
replace	cbo	=	7817	if	cod	==	7541
replace	cbo	=	7111	if	cod	==	7542
replace	cbo	=	7618	if	cod	==	7543
replace	cbo	=	5199	if	cod	==	7544
replace	cbo	=	7250	if	cod	==	7549
replace	cbo	=	7112	if	cod	==	8111
replace	cbo	=	7121	if	cod	==	8112
replace	cbo	=	7113	if	cod	==	8113
replace	cbo	=	8233	if	cod	==	8114
replace	cbo	=	8212	if	cod	==	8121
replace	cbo	=	7232	if	cod	==	8122
replace	cbo	=	8110	if	cod	==	8131
replace	cbo	=	8110	if	cod	==	8132
replace	cbo	=	8117	if	cod	==	8141
replace	cbo	=	8117	if	cod	==	8142
replace	cbo	=	8331	if	cod	==	8143
replace	cbo	=	7610	if	cod	==	8151
replace	cbo	=	7613	if	cod	==	8152
replace	cbo	=	7633	if	cod	==	8153
replace	cbo	=	7614	if	cod	==	8154
replace	cbo	=	7623	if	cod	==	8155
replace	cbo	=	7642	if	cod	==	8156
replace	cbo	=	5163	if	cod	==	8157
replace	cbo	=	7653	if	cod	==	8159
replace	cbo	=	8484	if	cod	==	8160
replace	cbo	=	8321	if	cod	==	8171
replace	cbo	=	7732	if	cod	==	8172
replace	cbo	=	8232	if	cod	==	8181
replace	cbo	=	8621	if	cod	==	8182
replace	cbo	=	7841	if	cod	==	8183
replace	cbo	=	8623	if	cod	==	8189
replace	cbo	=	7252	if	cod	==	8211
replace	cbo	=	7311	if	cod	==	8212
replace	cbo	=	7312	if	cod	==	8219
replace	cbo	=	7826	if	cod	==	8311
replace	cbo	=	7831	if	cod	==	8312
replace	cbo	=	5191	if	cod	==	8321
replace	cbo	=	7823	if	cod	==	8322
replace	cbo	=	7824	if	cod	==	8331
replace	cbo	=	7825	if	cod	==	8332
replace	cbo	=	6410	if	cod	==	8341
replace	cbo	=	7151	if	cod	==	8342
replace	cbo	=	7821	if	cod	==	8343
replace	cbo	=	7822	if	cod	==	8344
replace	cbo	=	7827	if	cod	==	8350
replace	cbo	=	5121	if	cod	==	9111
replace	cbo	=	5143	if	cod	==	9112
replace	cbo	=	5164	if	cod	==	9121
replace	cbo	=	5199	if	cod	==	9122
replace	cbo	=	5143	if	cod	==	9123
replace	cbo	=	5143	if	cod	==	9129
replace	cbo	=	6220	if	cod	==	9211
replace	cbo	=	6232	if	cod	==	9212
replace	cbo	=	6210	if	cod	==	9213
replace	cbo	=	6224	if	cod	==	9214
replace	cbo	=	6320	if	cod	==	9215
replace	cbo	=	6314	if	cod	==	9216
replace	cbo	=	7112	if	cod	==	9311
replace	cbo	=	9922	if	cod	==	9312
replace	cbo	=	7170	if	cod	==	9313
replace	cbo	=	7841	if	cod	==	9321
replace	cbo	=	7842	if	cod	==	9329
replace	cbo	=	5191	if	cod	==	9331
replace	cbo	=	7828	if	cod	==	9332
replace	cbo	=	7832	if	cod	==	9333
replace	cbo	=	5211	if	cod	==	9334
replace	cbo	=	5132	if	cod	==	9411
replace	cbo	=	5135	if	cod	==	9412
replace	cbo	=	5199	if	cod	==	9510
replace	cbo	=	5243	if	cod	==	9520
replace	cbo	=	5142	if	cod	==	9611
replace	cbo	=	5142	if	cod	==	9612
replace	cbo	=	5142	if	cod	==	9613
replace	cbo	=	4152	if	cod	==	9621
replace	cbo	=	4122	if	cod	==	9622
replace	cbo	=	4152	if	cod	==	9623
replace	cbo	=	7832	if	cod	==	9624
replace	cbo	=	5199	if	cod	==	9629

replace	cbo	=	1424	if	cod	==	1221
replace	cbo	=	1425	if	cod	==	1330
replace	cbo	=	1426	if	cod	==	1223
replace	cbo	=	2033	if	cod	==	2269
replace	cbo	=	2122	if	cod	==	2153

replace	cbo	=	2147	if	cod	==	2146
replace cbo =	2251	if cod ==	2211
replace cbo =	2252	if cod ==	2212
replace cbo =	2342	if cod ==	2310
replace cbo =	2343	if cod ==	2310
replace cbo =	2344	if cod ==	2310

replace cbo =	2345	if cod ==	2310
replace cbo =	2347	if cod ==	2310
replace cbo =	2348	if cod ==	2310
replace cbo =	2423	if cod ==	3355
replace cbo =	2621	if cod ==	3433
replace cbo =	3001	if cod ==	7421

replace cbo =	3003	if cod ==	7421
replace cbo =	3011	if cod ==	7421
replace cbo =	3012	if cod ==	3116
replace cbo =	3114	if cod ==	8141
replace cbo =	3115	if cod ==	2133

replace cbo =	3122	if cod ==	3112
replace cbo =	3123	if cod ==	2114
replace cbo =	3134	if cod ==	7312
replace cbo =	3135	if cod ==	3254
replace cbo =	3142	if cod ==	3115

replace cbo =	3143	if cod ==	3115
replace cbo =	3144	if cod ==	3115
replace cbo =	3146	if cod ==	7214
replace cbo =	3912	if cod ==	4321
replace cbo =	3951	if cod ==	2310


cd "$path"
save "output\COD_CBO_share_informality.dta", replace