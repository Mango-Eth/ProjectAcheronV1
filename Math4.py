import math

def calculate_inverse_square_root_price(square_root_price_x96, token0_decimals, token1_decimals):
    # Convert the square root price from Q96 format to a decimal value
    price_decimal = square_root_price_x96 / (2 ** 96)

    # Calculate the inverse price
    inverse_price = 1 / (price_decimal ** 2)

    # Adjust the inverse price based on the token decimals
    adjusted_inverse_price = inverse_price * (10 ** (token0_decimals - token1_decimals))

    # Convert the adjusted inverse price back to Q96 format
    inverse_square_root_price_x96 = int(math.sqrt(adjusted_inverse_price) * (2 ** 96))

    return inverse_square_root_price_x96


# Example usage
                        
square_root_price_x96 = 1896599640082824244384924832921

inverse_square_root_price_x96 = calculate_inverse_square_root_price(square_root_price_x96, 8, 6)
print(f"Inverse Square Root Price (Q96): {inverse_square_root_price_x96}")

# Verify the calculated inverse square root price
def calculate_price(sqrt_price_x96, decimals_token0, decimals_token1):
    price = (sqrt_price_x96 ** 2) / (2 ** 192)
    price_adjusted = price / (10 ** (decimals_token1 - decimals_token0))
    return price_adjusted

original_price = calculate_price(square_root_price_x96, 8, 6)
print(f"Original Price: {original_price}")

verified_inverse_price = calculate_price(3309660933560316374539252531, 6, 8)
print(f"Verified Inverse Price: {verified_inverse_price:.18f}")

# Verify that the inverse of the inverse square root price is the original square root price
reinverted_square_root_price_x96 = calculate_inverse_square_root_price(3309660933560316374539252531, 6, 8)
print(f"Reinverted Square Root Price (Q96): {reinverted_square_root_price_x96}")
  
# 3309660933560316374539252531
# 33096609335603163745392525312
# 3309660933560316814343903641          // WTF
# 33096609335603168143439036416         // Returned one
# 33096609335603168143439036            // Correct one  usdc/wbtc 6,8
# 1896599640082824244384924832921       // Original wbtc/usdc 8,6
# 

def calc(sqrtP, d0, d1):
    decimalPrice = calculate_price(sqrtP, d0, d1)

    inverse = 1 / decimalPrice

    #inversed decimal sub
    adjusted = (inverse ** 2) * (10 ** (d0 - d1))

    inverse_square_root_price_x96 = int(math.sqrt(adjusted) * (2 ** 96))

    return inverse_square_root_price_x96

print(f"C: {calc(1896599640082824244384924832921, 8, 6):.18f}")