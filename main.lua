-- paddle class and methods
local Paddle = {}
Paddle.__index = Paddle

local EPS = 1e-4
function Paddle.new(x,y,width,height,speed_y)
	local self = setmetatable({},Paddle)
	self.x,self.y = x,y
	self.width,self.height = width,height
	self.speed_y = speed_y
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
	local x,y,w,h = self.x,self.y,self.width,self.height
	return	x <= point_x-EPS and x + w >= point_x+EPS and
			y <= point_y-EPS and y + h >= point_y+EPS
end

function Paddle.draw(self)
	local x,y,w,h = self.x,self.y,self.width,self.height
	love.graphics.rectangle("fill", x, y, w, h)
end

function Paddle.moveDown(self,dt)
	self.y = self.y + self.speed_y*dt	
end

function Paddle.moveUp(self,dt)
	self.y = self.y - self.speed_y*dt	
end

-- ball class and methods
local Ball = {}
Ball.__index = Ball

function Ball.new(x,y,radius,speed_x,speed_y)
	local self = setmetatable({},Ball)
	self.x, self.y = x,y
	self.radius = radius
	self.speed_x = speed_x
	self.speed_y = speed_y
	return self
end

function Ball.draw(self)
	local x,y,r = self.x,self.y,self.radius
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

function Ball.getXSpeed(self)
	return self.speed_x
end

function Ball.getYSpeed(self)
	return self.speed_y
end

function Ball.horizontalBounce(self)
	self.speed_x = -self.speed_x
end

function Ball.verticalBounce(self)
	self.speed_y = -self.speed_y
end

function Ball.setSpeed(self,speed_x,speed_y)
	self.speed_x,self.speed_y = speed_x,speed_y
end

function Ball.setSpeedModule(self,speed_mod_x,speed_mod_y)
	 local dir_x = self.speed_x < EPS and -1 or 1
	 local dir_y = self.speed_y < EPS and -1 or 1

	 self.speed_x = dir_x * speed_mod_x
	 self.speed_y = dir_y * speed_mod_y
end

function Ball.move(self,dt)
	self.x = self.x + self.speed_x*dt
	self.y = self.y + self.speed_y*dt
end

-- love callback functions
do
	local left_paddle,right_paddle,ball
	local width,height
	local paddle_width,paddle_height,ball_radius
	local score_left, score_right
	local state,current_ball_owner
	local ball_speed

	function ball_follow(ball,current_ball_owner)
		if current_ball_owner:getX() < EPS then
			ball:setX(paddle_width+ball:getRadius())
		else 
			ball:setX(width - paddle_width - ball:getRadius())
		end
		ball:setY(current_ball_owner:getY() + paddle_height/2)
	end

	function restart_game()
		ball:setSpeed(ball_speed,-ball_speed)
		ball_follow(ball,current_ball_owner)
	end

	function love.load()
		width = love.graphics.getWidth()
		height = love.graphics.getHeight()
		
		paddle_height,paddle_width = 120,20
		paddle_start_height = height/2 - paddle_height
	
		ball_radius,ball_speed = 10,600

		left_paddle = Paddle.new(0,paddle_start_height,
			paddle_width,paddle_height,600)
		right_paddle = Paddle.new(width-paddle_width,
			paddle_start_height,paddle_height,paddle_height,600)
		ball = Ball.new(width/2,height/2,ball_radius)	

		score_left, score_right = 0, 0
		current_ball_owner = left_paddle

		love.graphics.setFont(love.graphics.newFont(20))
		love.graphics.setCaption('Pong!')

		state = 'serve'
	end

	function move_down(paddle,dt)
		paddle:moveDown(dt)
		if paddle:getY()+paddle_height >= height then 
			paddle:setY(height-paddle_height)
		end
	end
	
	function move_up(paddle,dt)
		paddle:moveUp(dt)
		if paddle:getY() < 0 then 
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

	function check_paddle_ball_collision(paddle,ball,dt)
		local bx,by,br = ball:getX(),ball:getY(),ball:getRadius()

		if paddle:collides(bx,by-br) then
			ball:verticalBounce()
			ball:setY(by+2*br)
		elseif paddle:collides(bx,by+br) then
			ball:verticalBounce()
			ball:setY(by-2*br)
		end

		if paddle:collides(bx-br,by) then
			ball:horizontalBounce()
			ball:setX(bx+2*br)
		elseif paddle:collides(bx+br,by) then
			ball:horizontalBounce()
			ball:setX(bx-2*br)
		end
	end

	function check_ball_arena_collision(ball)
		local x,y,r = ball:getX(),ball:getY(),ball:getRadius()
		if y <= 0 or y >= height-r then
			ball:verticalBounce()
			ball:setY(y <= EPS and 0 or height-r)	
		end
		if x+2*r <= EPS or x-2*r >= width+EPS then
			if x-2*r >= EPS+width then
				score_left = score_left + 1
				current_ball_owner = right_paddle
			elseif x+2*r <= EPS then
				score_right = score_right + 1
				current_ball_owner = left_paddle
			end
			state = 'serve'
			ball:setX(x <= EPS and 0 or width-r)
		end
	end

	function love.update(dt)
		local changed = false
		if love.keyboard.isDown("+") then
			ball_speed = ball_speed + 200*dt
			changed = true
		elseif love.keyboard.isDown("-") then
			ball_speed = ball_speed - 200*dt
			changed = true
		end

		if changed then
			ball:setSpeedModule(ball_speed,ball_speed)
		end

		if state == 'serve' then
			restart_game()
			state = 'serving'
		else	
			if state == 'serving' then
				if love.keyboard.isDown(' ') then
					state = 'playing'
				else
					ball_follow(ball,current_ball_owner)	
				end
			else
				check_paddle_ball_collision(left_paddle,ball,dt)
				check_paddle_ball_collision(right_paddle,ball,dt)
				check_ball_arena_collision(ball)
				ball:move(dt)
			end

			check_keys(left_paddle,"s","w",dt)
			check_keys(right_paddle,"k","i",dt)
		end
	end

	function draw_background()
		local line_length, i = 50,0
		while i < height do
			love.graphics.line(width/2,i,width/2,i+line_length)	
			i = i + line_length + 20
		end
	end

	function print_scores()
		love.graphics.print(score_left,width/2-25,0)
		love.graphics.print(score_right,width/2+10,0)
	end

	function draw_objects()
		left_paddle:draw()
		right_paddle:draw()
		ball:draw()
	end

	function love.draw()
		draw_background()
		draw_objects()
		print_scores()
	end
end
