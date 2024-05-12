def sqrt_price_x96_to_price(sqrt_price_x96, decimals_token0, decimals_token1):
    """
    Converts the sqrtPriceX96 value from Uniswap V3 to a regular price format.

    :param sqrt_price_x96: The sqrtPriceX96 value from Uniswap V3.
    :param decimals_token0: The number of decimals for token 0.
    :param decimals_token1: The number of decimals for token 1.
    :return: The price of token 0 in terms of token 1.
    """
    # Convert sqrtPriceX96 to the price of token 1 in terms of token 0
    price = (sqrt_price_x96 ** 2) / (2 ** 192)

    # Adjust for the difference in decimals between token 0 and token 1
    price_adjusted = price / (10 ** (decimals_token1 - decimals_token0))

    return price_adjusted

def sqrt_price_x96_to_priceCorrected(sqrt_price_x96, decimals_token0, decimals_token1):
    """
    # 18, 8
    """
    # Convert sqrtPriceX96 to the price of token 1 in terms of token 0
    price = (sqrt_price_x96 ** 2) / (2 ** 192)

    # Adjust for the difference in decimals between token 0 and token 1
    if decimals_token1 <= decimals_token0:
        price_adjusted = price * (10 ** ((18 - decimals_token1) + decimals_token0))
    else:
        price_adjusted = price * (10 ** decimals_token0)

    return price_adjusted

def price_to_sqrt_price_x96(price, decimals_token0, decimals_token1):
    """
    Converts a regular price of token 0 in terms of token 1 to sqrtPriceX96 format.

    :param price: The price of token 0 in terms of token 1.
    :param decimals_token0: The number of decimals for token 0.
    :param decimals_token1: The number of decimals for token 1.
    :return: The sqrtPriceX96 value.
    """
    # Adjust the price for the decimal difference between token 0 and token 1
    price_adjusted = price * (10 ** (decimals_token1 - decimals_token0))

    # Calculate sqrtPriceX96
    sqrt_price_x96 = (price_adjusted ** 0.5) * (2 ** 96)
    return int(sqrt_price_x96)

# Example usage:
sqrt_price_x96 = 3309660933560316814343903641
#sqrt_price_x96 = 2002706082180501472084972805163155558
#sqrt_price_x96 =   1823969275989850878615585130941513728
decimals_wbtc = 8  # WBTC has 8 decimals
decimals_dai = 18  # DAI has 18 decimals
18
# Calculate the price of WBTC in terms of DAI
price_of_wbtc_in_dai = sqrt_price_x96_to_price(8536811594165975124744711716116, 18, 18)

print(f"The price of WBTC in terms of DAI is: {price_of_wbtc_in_dai:.18f} DAI")

print("SqrtP:", price_to_sqrt_price_x96(20000, 18, 18))


# 10k sqrtP for tick: 792281625142643375935439503360000000          tick: 322378
# 200k sqrtP for tick: 3543191142285914282308094308233773056        tick: 352336
99999999999987713180
20000000000000000000
100000000

301492
199999999999990939279
# add 48713909086 -> 2e10 to whatever L you get from 1 pos


                        
# sqrtP (wbtc/usdc):    1896599640082824244384924832921 -> 57k 

def inverse(sqrtP, d0, d1):
    rawPrice = sqrt_price_x96_to_price(sqrtP, d0, d1)

    inversed = 1/rawPrice

    return price_to_sqrt_price_x96(inversed, d1, d0)



# print(price_to_sqrt_price_x96(0.00001757, 6, 8))
# print(f"{sqrt_price_x96_to_price(3320973915747366716257075200, 6, 8):.18f}")
# print(f"{sqrt_price_x96_to_price(1896599640082824244384924832921, 8, 6):.18f}")

# print(f"result: {inverse(1896599640082824244384924832921, 8, 6)}")
# print(f"{sqrt_price_x96_to_price(3309660933560316704392740864, 6, 8):.18f}")

#sqrtP (usdc/weth) 1454387275335648227030898134782397 (6,18)

# print(f"usdc/weth price     : {sqrt_price_x96_to_price(1454387275335648227030898134782397, 6, 18):.18f}")
# print(f"Inverse sqrtP       : {inverse(1454387275335648227030898134782397, 6, 18)}")
# print(f"Weth/usdc price     : {sqrt_price_x96_to_price(4315976797815444669988864, 18, 6):.18f}")

# print(f"xskirk/wbtc price     : {sqrt_price_x96_to_price(3441442688854942285824, 18, 8):.18f}")


print("Inverse Sqrtprice:", inverse(2046336672683425017101090566858, 18, 18))