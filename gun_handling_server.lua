local gs = require(game.ReplicatedStorage.gun_stats);
local pewpew = game.ReplicatedStorage:WaitForChild("gun_fired");
local debris = game:GetService("Debris");
local bullets = workspace.Bullets;

pewpew.OnServerEvent:Connect(function(plr, args)
	local distance = (args.StartPos - args.EndPos).magnitude;
	local bullet = Instance.new("Part", bullets);
	
	bullet.Size = Vector3.new(0.1, 0.1, distance);
	bullet.CFrame = CFrame.new((args.StartPos + args.EndPos) / 2, args.EndPos);
	
	bullet.Material = Enum.Material.Neon;
	bullet.BrickColor = args.Color;
	
	bullet.Anchored = true;
	bullet.CanCollide = false;
	
	debris:AddItem(bullet, 0.06);
	
	local ray = Ray.new(args.StartPos, (args.EndPos-args.StartPos).Unit * ((args.EndPos-args.StartPos).Magnitude + 1));
	local ignored = {};
	table.insert(ignored, bullets);
	table.insert(ignored, plr.Character);
	
	local hitpart, hitpos = workspace:FindPartOnRayWithIgnoreList(ray, ignored);
	
	local character;
	if not hitpart then return end;
	
	if hitpart:IsA("Accessory") then
		character = hitpart.Parent.Parent;
	else
		character = hitpart.Parent;
	end
	
	local target = game.Players:GetPlayerFromCharacter(character);
	
	if not character:FindFirstChild("Humanoid") or not target then return end;
	local humanoid = character:WaitForChild("Humanoid");
	
	if target.Team ~= plr.Team and args.Mode == "Normal" or args.Mode == "TK" then
		humanoid:TakeDamage(gs[args.Tool.Name].damage);
	elseif args.Mode == "Heal" then
		humanoid.Health += gs[args.Tool.Name].damage;
	elseif args.Mode == "Taser" then
		humanoid:TakeDamage(gs[args.Tool.Name].damage);
		
		if humanoid.WalkSpeed == 0 and humanoid.JumpPower == 0 and humanoid.Sit then return end;
		
		humanoid.WalkSpeed = 0;
		humanoid.JumpPower = 0;
		humanoid.Sit = true;
		
		wait(3);
		
		humanoid.WalkSpeed = 16;
		humanoid.JumpPower = 50;
		humanoid.Sit = false;
	end
end);
