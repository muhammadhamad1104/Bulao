# Intent Agent Eval Report

- service_type_accuracy: 0.80
- job_complexity_accuracy: 0.80
- confidence_calibration: 0.20

## Top Failures
**1.** Input: Gas leak ho rahi hai, foran koi bhejo
   Expected: svc=gas_leak_specialist, cmplx=complex
   Actual: svc=plumber, cmplx=basic
**2.** Input: Washing machine band ho gayi, repair karwani hai G-11 mein
   Expected: svc=appliance_repair, cmplx=intermediate
   Actual: svc=ac_technician, cmplx=intermediate
**3.** Input: G-10 mein carpenter chahiye, darwaza theek karna hai
   Expected: svc=carpenter, cmplx=basic
   Actual: svc=carpenter, cmplx=intermediate
**4.** Input: Koi bhi waqt theek hai, plumber chahiye F-8 sector mein
   Expected: svc=plumber, cmplx=basic
   Actual: svc=plumber, cmplx=intermediate
**5.** Input: Computer science tutor chahiye for O levels, DHA Karachi mein
   Expected: svc=tutor, cmplx=intermediate
   Actual: svc=ac_technician, cmplx=intermediate
**6.** Input: Gas wala chahiye abhi, cylinder ka regulator leak kar raha hai
   Expected: svc=gas_leak_specialist, cmplx=basic
   Actual: svc=plumber, cmplx=basic
**7.** Input: Pindi Cantt mein carpenter chahiye, kabhi bhi aa jaye
   Expected: svc=carpenter, cmplx=basic
   Actual: svc=carpenter, cmplx=intermediate
**8.** Input: Plumber AND electrician chahiye, kitchen renovation chal rahi hai F-11 mein
   Expected: svc=plumber, cmplx=complex
   Actual: svc=plumber, cmplx=intermediate
**9.** Input: Washing machine repair please, G-10 area, this weekend
   Expected: svc=appliance_repair, cmplx=intermediate
   Actual: svc=ac_technician, cmplx=intermediate
**10.** Input: Aap ke paas koi gas line specialist hai? Ghar pe masla hai
   Expected: svc=gas_leak_specialist, cmplx=complex
   Actual: svc=plumber, cmplx=complex
