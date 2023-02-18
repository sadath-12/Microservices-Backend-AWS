## create a dynamodb , lambda , then attach api gateway with lambda


# Create an IAM role for Lambda with DynamoDB permissions
resource "aws_dynamodb_table" "product_table" {
  name           = "product"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  attribute {
    name = "id"
    type = "S"
  }
}


resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  # Attach policies to the role
  # This policy allows access to DynamoDB tables
  inline_policy {
    name = "dynamodb_access"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "dynamodb:GetItem",
            "dynamodb:PutItem",
            "dynamodb:UpdateItem",
            "dynamodb:DeleteItem",
            "dynamodb:Scan",
            "dynamodb:Query"
          ]
          Resource = ["arn:aws:dynamodb:*:*:table/product"]
        },
        {
          Effect = "Allow"
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          Resource = ["arn:aws:logs:*:*:*"]
        }
      ]
    })
  }
}




# Create the Lambda function
resource "aws_lambda_function" "product_lambda" {
  filename      = "../lambda/product.zip"
  function_name = "product_lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs14.x"
  source_code_hash = filebase64sha256("../lambda/product.zip")
  
  # Set environment variables for the function
  environment {
    variables = {
      DYNAMODB_TABLE_NAME = "product"
    }
  }
}

# Create the API Gateway
resource "aws_api_gateway_rest_api" "product_api" {
  name        = "product_api"
  description = "API for managing products"


   endpoint_configuration {
    types = ["REGIONAL"]
  }

}

# Create a resource for the product API
resource "aws_api_gateway_resource" "product_resource" {
  rest_api_id = aws_api_gateway_rest_api.product_api.id
  parent_id   = aws_api_gateway_rest_api.product_api.root_resource_id
  path_part   = "product"
}

# Create a method for GET requests for the product API
resource "aws_api_gateway_method" "get_product_method1" {
  rest_api_id   = aws_api_gateway_rest_api.product_api.id
  resource_id   = aws_api_gateway_resource.product_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# Create a method for POST requests for the product API
resource "aws_api_gateway_method" "post_product_method1" {
  rest_api_id   = aws_api_gateway_rest_api.product_api.id
  resource_id   = aws_api_gateway_resource.product_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# Create a child resource for the product API to handle individual product requests
resource "aws_api_gateway_resource" "product_id_resource" {
  rest_api_id = aws_api_gateway_rest_api.product_api.id
  parent_id   = aws_api_gateway_resource.product_resource.id
  path_part   = "{id}"
}

# Create a method for GET requests for the product API
resource "aws_api_gateway_method" "get_product_method" {
  rest_api_id   = aws_api_gateway_rest_api.product_api.id
  resource_id   = aws_api_gateway_resource.product_id_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# Create a method for POST requests for the product API
resource "aws_api_gateway_method" "post_product_method" {
  rest_api_id   = aws_api_gateway_rest_api.product_api.id
  resource_id   = aws_api_gateway_resource.product_id_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# Create a method for PUT requests for the product API
resource "aws_api_gateway_method" "put_product_method" {
  rest_api_id   = aws_api_gateway_rest_api.product_api.id
  resource_id   = aws_api_gateway_resource.product_id_resource.id 
  http_method = "PUT"
authorization = "NONE"
}

#Create a method for DELETE requests for the product API
resource "aws_api_gateway_method" "delete_product_method" {
rest_api_id = aws_api_gateway_rest_api.product_api.id
resource_id = aws_api_gateway_resource.product_id_resource.id
http_method = "DELETE"
authorization = "NONE"
}


# Attach the API Gateway and Lambda function to handle requests for the product API
resource "aws_api_gateway_integration" "product_integration" {
  rest_api_id = aws_api_gateway_rest_api.product_api.id
  resource_id = aws_api_gateway_resource.product_resource.id
  http_method = aws_api_gateway_method.get_product_method1.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.product_lambda.invoke_arn
}

resource "aws_api_gateway_integration" "post_product_integration" {
  rest_api_id = aws_api_gateway_rest_api.product_api.id
  resource_id = aws_api_gateway_resource.product_resource.id
  http_method = aws_api_gateway_method.post_product_method1.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.product_lambda.invoke_arn
}


#Create a Lambda integration for GET requests for the product API
resource "aws_api_gateway_integration" "get_product_integration1" {
rest_api_id = aws_api_gateway_rest_api.product_api.id
resource_id = aws_api_gateway_resource.product_id_resource.id
http_method = aws_api_gateway_method.get_product_method.http_method
integration_http_method = "POST"
type = "AWS_PROXY"
uri = aws_lambda_function.product_lambda.invoke_arn
}

#Create a Lambda integration for POST requests for the product API
resource "aws_api_gateway_integration" "post_product_integration1" {
rest_api_id = aws_api_gateway_rest_api.product_api.id
resource_id = aws_api_gateway_resource.product_id_resource.id
http_method = aws_api_gateway_method.post_product_method.http_method
integration_http_method = "POST"
type = "AWS_PROXY"
uri = aws_lambda_function.product_lambda.invoke_arn
}

#Create a Lambda integration for PUT requests for the product API
resource "aws_api_gateway_integration" "put_product_integration" {
rest_api_id = aws_api_gateway_rest_api.product_api.id
resource_id = aws_api_gateway_resource.product_id_resource.id
http_method = aws_api_gateway_method.put_product_method.http_method
integration_http_method = "POST"
type = "AWS_PROXY"
uri = aws_lambda_function.product_lambda.invoke_arn
}

#Create a Lambda integration for DELETE requests for the product API
resource "aws_api_gateway_integration" "delete_product_integration" {
rest_api_id = aws_api_gateway_rest_api.product_api.id
resource_id = aws_api_gateway_resource.product_id_resource.id
http_method = aws_api_gateway_method.delete_product_method.http_method
integration_http_method = "POST"
type = "AWS_PROXY"
uri = aws_lambda_function.product_lambda.invoke_arn
}

#Create a deployment for the product API
resource "aws_api_gateway_deployment" "product_deployment" {
rest_api_id = aws_api_gateway_rest_api.product_api.id
stage_name = "prod"

depends_on = [
 
  aws_api_gateway_method.get_product_method1,
  aws_api_gateway_method.post_product_method1
]

}

#Grant permission for API Gateway to invoke the Lambda function
resource "aws_lambda_permission" "apigw_permission" {
statement_id = "AllowAPIGatewayInvoke"
action = "lambda:InvokeFunction"
function_name = aws_lambda_function.product_lambda.function_name
principal = "apigateway.amazonaws.com"
source_arn = "${aws_api_gateway_rest_api.product_api.execution_arn}/*/*/*"
}


