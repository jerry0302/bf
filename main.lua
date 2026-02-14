local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
local Window = OrionLib:MakeWindow({Name = "My Custom Hub", HidePremium = false, SaveConfig = false})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

local Config = {
    AutoFarm = false,
    AttackDist = 25,
    TweenSpeed = 280, -- 推荐 250-300，兼顾速度与安全
    AutoSkills = true
}

-- [防侦测/功能模块] --

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- NoClip (穿墙防止卡顿)
RunService.Stepped:Connect(function()
    if Config.AutoFarm and LocalPlayer.Character then
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
            end
        end
    end
end)

-- 安全平滑飞行函数
local function safeTween(targetCFrame)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local root = char.HumanoidRootPart
    local dist = (root.Position - targetCFrame.Position).Magnitude
    
    if dist < 5 then
        root.CFrame = targetCFrame
        return
    end

    local tween = TweenService:Create(root, TweenInfo.new(dist / Config.TweenSpeed, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
    
    -- 防止重力干扰
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.Parent = root
    
    tween:Play()
    tween.Completed:Wait()
    bv:Destroy()
end

-- 获取怪物的文件夹 (Blox Fruits 专用)
local function getEnemies()
    return workspace:FindFirstChild("Enemies") or workspace
end

-- 获取最近的目标
local function getTarget()
    local dist = 1000
    local target = nil
    for _, v in pairs(getEnemies():GetChildren()) do
        if v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 and v:FindFirstChild("HumanoidRootPart") then
            local mag = (LocalPlayer.Character.HumanoidRootPart.Position - v.HumanoidRootPart.Position).Magnitude
            if mag < dist then
                dist = mag
                target = v
            end
        end
    end
    return target
end

-- [GUI 界面] --

local Tab = Window:MakeTab({Name = "Farm", Icon = "rbxassetid://4483345998"})

Tab:AddToggle({
    Name = "Auto Farm",
    Default = false,
    Callback = function(v) Config.AutoFarm = v end
})

Tab:AddToggle({
    Name = "Auto Skills",
    Default = true,
    Callback = function(v) Config.AutoSkills = v end
})

-- [核心循环] --

task.spawn(function()
    while task.wait() do
        if Config.AutoFarm then
            pcall(function()
                local target = getTarget()
                if target then
                    -- 移动到怪物上方
                    safeTween(target.HumanoidRootPart.CFrame * CFrame.new(0, Config.AttackDist, 0))
                    
                    -- 自动普攻
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton1(Vector2.new(800, 600))
                    
                    -- 自动技能
                    if Config.AutoSkills then
                        local vim = game:GetService("VirtualInputManager")
                        for _, key in pairs({"Z", "X", "C", "V"}) do
                            vim:SendKeyEvent(true, key, false, game)
                            task.wait(0.05)
                            vim:SendKeyEvent(false, key, false, game)
                        end
                    end
                end
            end)
        end
    end
end)

OrionLib:Init()
