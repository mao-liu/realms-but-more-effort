resource "aws_vpc" "main" {
    cidr_block = "10.32.0.0/16"
}

resource "aws_subnet" "public" {
    for_each = {
        "ap-southeast-2a": "10.32.8.0/24",
        "ap-southeast-2b": "10.32.9.0/24",
        "ap-southeast-2c": "10.32.10.0/24"
    }

    availability_zone = each.key
    cidr_block        = each.value
    vpc_id            = aws_vpc.main.id
    map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main.id
}

resource "aws_default_route_table" "main" {
    default_route_table_id = aws_vpc.main.default_route_table_id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
}

resource "aws_default_security_group" "main" {
    vpc_id = aws_vpc.main.id

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
}
