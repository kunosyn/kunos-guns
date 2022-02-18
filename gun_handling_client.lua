local ctx = game:GetService("ContextActionService");

local player = game.Players.LocalPlayer;
local mouse = player:GetMouse();

local character = player.Character or player.CharacterAdded:Wait();
local humanoid = character:WaitForChild("Humanoid");
local head = character:WaitForChild("Head");

local gs = require(game.ReplicatedStorage.gun_stats)[script.Parent.Name];
local gun = {
	["tool"] = script.Parent,
	["equipped"] = false,
	["reloading"] = false,
	["debounce"] = false,
	["stats"] = gs,
	["barrel"] = script.Parent:FindFirstChild("barrel"),
	["bullets"] = script:WaitForChild("bullets"),
	["mode"] = script:WaitForChild("mode"),
	["ui"] = player.PlayerGui:WaitForChild("gunGui").screenFrame
}

local renderbullet = game.ReplicatedStorage:WaitForChild("gun_fired");

gun.ui.Frame.NameBox.Text = script.Parent.Name;
gun.ui.Frame.BulletsBox.Text = gun.stats.bullets.."/"..gun.stats.bullets;

function pLoadAnim(id)
	local anim = Instance.new("Animation", script);
	anim.Name = "GunAnimation"..id;
	anim.AnimationId = "rbxassetid://"..id;
	
	anim = humanoid:WaitForChild("Animator"):LoadAnimation(anim);
	
	anim:Play();
	anim:Stop();
	
	return anim;
end

local animations = {
	["shoot"] = pLoadAnim(8859196288),
	["down"] = pLoadAnim(8859191673),
	["idle"] = pLoadAnim(8859182459)
}

function getColor()
	local colors = {
		["Normal"] = player.TeamColor,
		["Heal"] = BrickColor.new("Bright green"),
		["TK"] = BrickColor.new("New Yeller"),
		["Taser"] = BrickColor.new("New Yeller");
	}
	
	return colors[gun.mode.Value];
end

function getUIColor()
	local colors = {
		["Normal"] = Color3.new(169/255, 217/255, 114/255),
		["Heal"] = Color3.new(0, 1, 0.0313725),
		["TK"] = Color3.new(1, 0.980392, 0.403922),
		["Taser"] = Color3.new(255, 255, 0)
	}
	
	return colors[gun.mode.Value];
end

function gun:reload()
	animations.shoot:Stop();
	animations.down:Stop();
	
	humanoid.WalkSpeed = 16;
	animations.idle:Play();

	if not gun.reloading then
		gun.ui.Frame.BulletsBox.Text = "Reloading...";

		gun.reloading = true;
		wait(gun.stats.reloadspeed);
		gun.reloading = false;

		gun.bullets.Value = gun.stats.bullets;
		gun.ui.Frame.BulletsBox.Text = gun.stats.bullets.."/"..gun.stats.bullets;
	end
end


local shoot_func = function(_, input_type)
	if input_type == Enum.UserInputState.Begin then
		if gun.reloading then return end;
		
		animations.idle:Stop();
		animations.down:Stop();
		humanoid.WalkSpeed = 16;
		
		if gun.stats.auto then
			if not gun.debounce then
				gun.shooting = true;
				
				animations.shoot:Play();
				
				while gun.shooting and gun.equipped and not gun.reloading do
					if gun.bullets.Value <= 0 then 
						gun:reload();
						break;
					end;
					
					local pos = (mouse.Hit.Position - head.Position).Unit * 1000;
					local distance = (gun.barrel.tip.Position - pos).Magnitude;

					local args = {};

					args.Tool = gun.tool;
					args.Color = getColor();
					args.Mode = gun.mode.Value;
					args.StartPos = gun.tool.barrel.tip.Position;

					local ray = Ray.new(head.Position, pos);

					local ignored = {};
					table.insert(ignored, workspace.Bullets);
					table.insert(ignored, player.Character);

					local hitpart, hitpos = workspace:FindPartOnRayWithIgnoreList(ray, ignored);

					args.EndPos = hitpos;
					renderbullet:FireServer(args);
					
					gun.bullets.Value -= 1;
					gun.ui.Frame.BulletsBox.Text = gun.bullets.Value.."/"..gun.stats.bullets;

					gun.debounce = true;
					wait(gun.stats.firerate);
					gun.debounce = false;
				end

				gun.shooting = false;
				animations.shoot:Stop();
				animations.idle:Play();
			else 
				wait(gun.stats.firerate);
				gun.debounce = false;
			end
		else
			if not gun.debounce then
				if gun.bullets.Value <= 0 then return gun:reload() end;
				
				local pos = (mouse.Hit.Position - head.Position).Unit * 1000;
				local distance = (gun.barrel.tip.Position - pos).Magnitude;

				local args = {};

				args.Tool = gun.tool;
				args.Color = getColor();
				args.Mode = gun.mode.Value;
				args.StartPos = gun.tool.barrel.tip.Position;

				local ray = Ray.new(head.Position, pos);

				local ignored = {};
				table.insert(ignored, workspace.Bullets);
				table.insert(ignored, player.Character);

				local hitpart, hitpos = workspace:FindPartOnRayWithIgnoreList(ray, ignored);

				args.EndPos = hitpos;
				renderbullet:FireServer(args);
				
				gun.bullets.Value -= 1;
				gun.ui.Frame.BulletsBox.Text = gun.bullets.Value.."/"..gun.stats.bullets;
				
				animations.shoot:Play();
				gun.debounce = true;
				wait(gun.stats.firerate);
				gun.debounce = false;
				animations.shoot:Stop();
				
				animations.idle:Play();
			else
				wait(gun.stats.firerate);
				gun.debounce = false;
			end
		end
	else
		gun.shooting = false;

		gun.debounce = true;
		wait(gun.stats.firerate);
		gun.debounce = false;
	end
end

local reload_func = function(_, input_type)
	if input_type ~= Enum.UserInputState.Begin or gun.stats.bullets == gun.bullets.Value then return end;
	
	gun:reload();
end

local sprint_func = function(_, input_type)
	if input_type ~= Enum.UserInputState.Begin then return end;

	if humanoid.WalkSpeed == 16 then
		humanoid.WalkSpeed = 20;
		
		gun.shooting = false;
		
		animations.shoot:Stop();
		animations.idle:Stop();
		
		animations.down:Play();
	else
		humanoid.WalkSpeed = 16;
		animations.down:Stop();
		animations.idle:Play();
	end
end

local cycle_mode_func = function(_, input_type)
	if input_type ~= Enum.UserInputState.Begin then return end;
	
	local next_value = gun.stats.modes[next(gun.stats.modes, table.find(gun.stats.modes, gun.mode.Value))];
	
	if not next_value then
		next_value = gun.stats.modes[1];
	end
	
	gun.mode.Value = next_value;
	gun.ui.Frame.ModeBox.Text = gun.mode.Value;
	gun.ui.Frame.ModeBox.TextColor3 = getUIColor();
end

gun.tool.Equipped:Connect(function()
	gun.equipped = true;
	gun.ui.Visible = true;
	
	animations.idle:Play();
	
	ctx:BindAction("Shoot", shoot_func, false, Enum.UserInputType.MouseButton1);
	ctx:BindAction("Reload", reload_func, false, Enum.KeyCode.R);
	ctx:BindAction("Sprint", sprint_func, false, Enum.KeyCode.F);
	ctx:BindAction("Mode", cycle_mode_func, false, Enum.KeyCode.T);
end);

gun.tool.Unequipped:Connect(function()
	gun.equipped = false;
	gun.ui.Visible = false;
	
	mouse.Icon = "http://www.roblox.com/asset/?id=";
	
	animations.shoot:Stop();
	animations.idle:Stop();
	animations.down:Stop();
	
	ctx:UnbindAction("Shoot");
	ctx:UnbindAction("Reload");
	ctx:UnbindAction("Sprint");
	ctx:UnbindAction("Mode");
end);

mouse.Move:Connect(function()
	if gun.equipped then 
		local character;
		
		if not mouse.Target then 
			mouse.Icon = "http://www.roblox.com/asset/?id=131581677";
			return;
		end
		
		if mouse.Target:IsA("Accessory") then
			character = mouse.Target.Parent.Parent;
		elseif  mouse.Target.Parent:FindFirstChild("Humanoid") then
			character = mouse.Target.Parent;
		end
		
		if character then
			local target = game.Players:GetPlayerFromCharacter(character);
			
			if not target then 
				mouse.Icon = "http://www.roblox.com/asset/?id=131581677";
				return;
			end;
			
			if player.Team == target.Team then
				mouse.Icon = "http://www.roblox.com/asset/?id=131718487";
			else
				mouse.Icon = "http://www.roblox.com/asset/?id=131718495";
			end
		else
			mouse.Icon = "http://www.roblox.com/asset/?id=131581677";
		end
	else
		mouse.Icon = "http://www.roblox.com/asset/?id=";
	end
end);
