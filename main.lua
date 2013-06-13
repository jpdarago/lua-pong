-- paddle class and methods
local Paddle = {}
Paddle.__index = Paddle

function Paddle.new(x,y,width,height)
	local self = setmetatable({},Paddle)
	self.x,self.y = x,y
	self.width,self.height = width,height
	return self
end

function Paddle.getX(self)
	return self.x
end

function Paddle.getY(self)
	return self.y
end

function Paddle.setY(self,y)
	 self.y = y
end

function Paddle.collides(self,point_x,point_y)
	x,y,w,h = self.x,self.y,self.width,self.height
	return	x <= point_x and x + w >= point_x and
			y <= point_y and y + h >= point_y
end

function Paddle.draw(self)
	x,y,w,h = self.x,self.y,self.width,self.height
	love.graphics.rectangle("fill", x, y, w, h)
end

-- ball class and methods
local Ball = {}
Ball.__index = Ball

function Ball.new(x,y,radius)
	local self = setmetatable({},Ball)
	self.x, self.y = x,y
	self.radius = radius
	return self
end

function Ball.collides(self,point_x,point_y)
	x,y,r = self.x, self.y, self.radius
	dx,dy = point_x - x, point_y - y
	return dx*dx + dy*dy <= r*r
end

function Ball.draw(self)
	x,y,r = self.x,self.y,self.radius
	love.graphics.circle("fill", x, y, r)
end

function Ball.getX(self)
	return self.x
end

function Ball.setX(self,x)
	self.x = x
end

function Ball.getY(self)
	return self.y
end

function Ball.setY(self,y)
	self.y = y
end

function Ball.getRadius(self)
	return self.radius
end

-- love callback functions
do
	local left_paddle,right_paddle,ball
	local width,height
	local paddle_width,paddle_height,ball_radius
	local ball_x_speed,ball_y_speed
	local paddle_x_speed,paddle_y_speed
	local score_left, score_right
	local state,current_ball_owner

	function ball_follow(ball,current_ball_owner)
		if current_ball_owner:getX() == 0 then
			ball:setX(paddle_width+ball:getRadius())
		else 
			ball:setX(width - paddle_width - ball:getRadius())
		end
		ball:setY(current_ball_owner:getY() + paddle_height/2)
	end

	function restart_game()
		ball_x_speed,ball_y_speed = 13,-13
		ball_follow(ball,current_ball_owner)
	end

	function love.load()
		width = love.graphics.getWidth()
		height = love.graphics.getHeight()
		
		paddle_height,paddle_width = 120,20
		paddle_start_height = height/2 - paddle_height
		paddle_x_speed,paddle_y_speed = 0,650
	
		ball_radius = 10

		left_paddle = Paddle.new(0,paddle_start_height,
			paddle_width,paddle_height)
		right_paddle = Paddle.new(width-paddle_width,
			paddle_start_height,paddle_height,paddle_height)
		ball = Ball.new(width/2,height/2,ball_radius)	

		score_left, score_right = 0, 0
		current_ball_owner = left_paddle

		love.graphics.setFont(love.graphics.newFont(20))
		love.graphics.setCaption('Pong!')

		state = 'serve'
	end

	function move_down(paddle,dt)
		local new_y = paddle:getY() + dt*paddle_y_speed
		if new_y + paddle_height < height then 
			paddle:setY(new_y)
		end
	end
	
	function move_up(paddle,dt)
		local new_y = paddle:getY() - dt*paddle_y_speed
		paddle:setY(new_y)
		if new_y < 0 then 
			paddle:setY(0)
		end
	end

	function check_keys(paddle,down_key,up_key,dt)
		if love.keyboard.isDown(down_key) then
			move_down(paddle,dt)
		elseif love.keyboard.isDown(up_key) then
			move_up(paddle,dt)	
		end
	end

	function check_paddle_ball_collision(paddle,ball)
		bx,by,br = ball:getX(),ball:getY(),ball:getRadius()

		if paddle:collides(bx,by-br) then
			ball_y_speed = -ball_y_speed
			ball:setY(by+br)
		elseif paddle:collides(bx,by+br) then
			ball_y_speed = -ball_y_speed
			ball:setY(by-br)
		end

		if paddle:collides(bx-br,by) then
			ball_x_speed = -ball_x_speed
			ball:setX(bx+br)
		elseif paddle:collides(bx+br,by) then
			ball_x_speed = -ball_x_speed
			ball:setX(bx-br)
		end
	end

	function check_ball_arena_collision(ball)
		local x,y,r = ball:getX(),ball:getY(),ball:getRadius()
		if y <= 0 or y >= height-r then
			ball_y_speed = -ball_y_speed
			if y <= 0 then	
				ball:setY(0)
			else 
				ball:setY(height-r)	
			end
		end
		if x <= 0 or x >= width-r then
			if x >= width-r then
				score_left = score_left + 1
				current_ball_owner = right_paddle
			end
			if x <= 0 then
				score_right = score_right + 1
				current_ball_owner = left_paddle
			end
			state = 'serve'
			ball_x_speed = -ball_x_speed
			if x <= 0 then
				ball:setX(0)
			else
				ball:setX(width-r)
			end
		end
	end

	function move_ball(ball)
		ball:setX(ball:getX()+ball_x_speed)
		ball:setY(ball:getY()+ball_y_speed)
	end

	function love.update(dt)
		if state == 'serve' then
			restart_game()
			state = 'serving'
		else
			check_keys(left_paddle,"s","w",dt)
			check_keys(right_paddle,"k","i",dt)
			
			if state == 'serving' then
				if love.keyboard.isDown(' ') then
					state = 'playing'
				else
					ball_follow(ball,current_ball_owner)	
				end
			else
				check_paddle_ball_collision(left_paddle,ball)
				check_paddle_ball_collision(right_paddle,ball)
				check_ball_arena_collision(ball)
				move_ball(ball)
			end
		end
	end

	function draw_middle_line()
		local line_length, i = 50,0
		while i < height do
			love.graphics.line(width/2,i,width/2,i+line_length)	
			i = i + line_length + 20
		end
	end

	function love.draw()
		left_paddle:draw()
		right_paddle:draw()
		ball:draw()
		love.graphics.print(score_left,width/2-25,0)
		love.graphics.print(score_right,width/2+10,0)
		draw_middle_line();
	end
end
