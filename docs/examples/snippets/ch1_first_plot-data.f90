it = [(real(i, R8P), i = 1, 120)]
res = 10.0_R8P**(-0.045_R8P * it) * (1.0_R8P + 0.35_R8P * sin(it / 3.0_R8P))
