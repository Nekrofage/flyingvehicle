local function get_sign(i)
    if i == 0 then
        return 0
    else
        return i/math.abs(i)
    end
end

local function get_velocity(vx, vy, vz, yaw)
    local x = math.cos(yaw)*vx+math.cos(math.pi/2+yaw)*vz
    local z = math.sin(yaw)*vx+math.sin(math.pi/2+yaw)*vz
    return {x=x, y=vy, z=z}
end

local function get_v(v)
    return math.sqrt(v.x^2+v.z^2)
end


local box = {
    physical = true,
    collisionbox = {-0.5,-0.5,-0.5, 0.5,0.5,0.5},
    visual = "mesh",
    mesh="controller.x",
    textures = {"default_wood.png","default_wood.png","default_wood.png","default_wood.png","default_wood.png","default_wood.png"},
    visual_size = {x=1, y=1},
}

local controller = {
    physical = true,
    collisionbox = {-0.5,-0.5,-0.5, 0.5,0.5,0.5},
    visual = "mesh",
    mesh="controller.x",
    textures = {"flyingvehicle_controller.png","flyingvehicle_controller.png","flyingvehicle_controller.png","flyingvehicle_controller.png","flyingvehicle_controller.png","flyingvehicle_controller.png"},
    vx = 0,--Velo. for/back-ward
    vy = 0,--Velo. up/down
    vz = 0,--Velo. side
    driver = nil,
}

function controller:on_rightclick(clicker)
    if not clicker or not clicker:is_player() then
        return
    end
    if self.driver and clicker == self.driver then
        self.driver = nil
        clicker:set_detach()
    elseif not self.driver then
        self.driver = clicker
        clicker:set_attach(self.object, "", {x=0,y=0,z=0}, {x=0,y=0,z=0})
    end
end

function controller:on_punch(puncher, time_from_last_punch, tool_capabilities, direction)
    self.object:remove()
    if puncher and puncher:is_player() then
        puncher:get_inventory():add_item("main", "flyingvehicle:controller")
    end
end

function box:on_punch(puncher, time_from_last_punch, tool_capabilities, direction)
    self.object:remove()
    if puncher and puncher:is_player() then
        puncher:get_inventory():add_item("main", "default:wood")
    end
end

function controller:on_step(dtime)
    --self.v = get_v(self.object:getvelocity())*get_sign(self.v)
    if self.driver then
        local ctrl = self.driver:get_player_control()
        --Forward/backward
        if ctrl.up then
            self.vx = self.vx+0.1
        end

        if ctrl.down then
            self.vx = self.vx-0.08
        end

        --Left/right
        if ctrl.left then
            --self.vz = self.vz+0.1
            self.object:setyaw(self.object:getyaw()+math.pi/120+dtime*math.pi/120)
        end

        if ctrl.right then
            --self.vz = self.vz-0.1
            self.object:setyaw(self.object:getyaw()-math.pi/120-dtime*math.pi/120)
        end
        --up/down
        if ctrl.jump then
            if self.vy<1.5 then
                self.vy = self.vy+0.2
            end
        end
        if ctrl.sneak then
            if self.vy>-1.5 then
                self.vy = self.vy-0.2
            end
        end
        --
        --self.object:setyaw(self.driver:get_look_yaw())
    end
    --Decelerating
    local sx=get_sign(self.vx)
    self.vx = self.vx - 0.02*sx

    local sz=get_sign(self.vz)
    self.vz = self.vz - 0.02*sz

    local sy=get_sign(self.vy)
    self.vy = self.vy-0.01*sy

    --Stop
    if sx ~= get_sign(self.vx) then
        self.vx = 0
    end

    if sz ~= get_sign(self.vz) then
        self.vz = 0
    end

    if sy ~= get_sign(self.vy) then
        self.vy = 0
    end

    --Speed limit
    if math.abs(self.vx) > 4.5 then
        self.vx = 4.5*get_sign(self.vx)
    end

    if math.abs(self.vz) > 4.5 then
        self.vz = 4.5*get_sign(self.vz)
    end

    --Set speed to entity
    self.object:setvelocity(get_velocity(self.vx, self.vy, self.vz, self.object:getyaw()))
end

minetest.register_entity("flyingvehicle:box", box)
minetest.register_entity("flyingvehicle:controller", controller)

minetest.register_craftitem("flyingvehicle:controller", {
    description = "controller",
    inventory_image = "flyingvehicle_controller.png",
    wield_image = "flyingvehicle_controller.png",
    wield_scale = {x=1, y=1, z=1},
    liquids_pointable = false,
    on_place = function(itemstack, placer, pointed_thing)
        if pointed_thing.type ~= "node" then
            return
        end
        local pos = pointed_thing.under
        local height =0
        local lx = 0
        local lz = 0
        local node = minetest.env:get_node(pos)
        for i=1,10 do
            node = minetest.env:get_node(pos)
            if node.name=="default:steelblock" then
                height = i
                pos.y=pos.y+i
                minetest.chat_send_all("OK. height : "..height)
                break
            end
            pos.y = pos.y-1
            if i==9 then
                return
            end
        end
        local object = minetest.env:add_entity(pos, "flyingvehicle:controller")
        --Find a corner of steel plane
        pos.y=pos.y-height
        for i=1,50 do
            node = minetest.env:get_node(pos)
            if node.name~="default:steelblock" then
                pos.x = pos.x+1
                lx=i-2
                minetest.chat_send_all("OK. lx : "..lx)
                break
            end
            pos.x = pos.x-1
            if i==50 then
                return
            end
        end
        for i=1,50 do
            node = minetest.env:get_node(pos)
            if node.name~="default:steelblock" then
                pos.z=pos.z+1
                lz=i-2
                minetest.chat_send_all("OK. lz : "..lz)
                break
            end
            pos.z = pos.z-1
            if i==50 then
                return
            end
        end
        --Replacing by entities
        local h=0
        for i=0,50 do
            for j=0,50 do
                node = minetest.env:get_node(pos)
                if node.name~="default:steelblock" then
                    pos.x = pos.x-j
                    break
                end

                for v=0,50 do
                    pos.y=pos.y+1
                    h=v+1
                    node = minetest.env:get_node(pos)
                    if node.name=="default:wood" then
                        minetest.env:remove_node(pos)
                        local object2=minetest.env:add_entity(pos, "flyingvehicle:box")
                        object2:set_attach(object,"Armature", {x=(j-lx)*10,y=(v-height+1)*10,z=(i-lz)*10}, {x=0,y=0,z=0})
                    end

                end

                pos.y=pos.y-h
                pos.x = pos.x+1
            end

            pos.z = pos.z+1
            node = minetest.env:get_node(pos)
            if node.name~="default:steelblock" then
                minetest.chat_send_all("OK. x : "..pos.x.." z : "..pos.z-1)
                pos.x = pos.x+lx
                pos.z = pos.z-i+lz-1
                pos.y = pos.y+height+1
                --minetest.env:add_entity(pos, "flyingvehicle:box")
                break
            end
        end
        itemstack:take_item()
        return itemstack
    end,
})


minetest.register_chatcommand("vehicle", {
    params = "<entity name> <entity param>",
    description = "Add an vehicle with parameters",
    func = function(user, args)

        if args == "" then
            return false, "Parameters required."
        end

        local vehicleAction, vehicleParam = args:match("^(%S+)%s(%S+)$")

        if not vehicleParam then
            return false, "Entity parameters required"
        end

        local player = minetest.get_player_by_name(user)
        if not player then
            return false, "Player not found"
        end

        local fmt = "Add an %s vehicle at: (%.2f,%.2f,%.2f)"

        local pos = player:getpos()

        -- /vehicle add 1
        if vehicleAction == "add" then
            minetest.chat_send_player(user, "Add vehicle  " .. vehicleParam)

            if vehicleParam == "1" then
                -- y = height
                for i=0,7 do
                    for j=0,4 do
                        minetest.set_node({x=pos.x + i, y=pos.y, z=pos.z + j}, {name="default:steelblock"})
                    end
                end


                for i=0,7 do
                    for j=0,4 do
                        minetest.set_node({x=pos.x + i, y=pos.y + 1, z=pos.z + j}, {name="default:wood"})
                    end
                end

                minetest.set_node({x=pos.x + 7, y=pos.y + 2, z=pos.z + 2}, {name="default:wood"})
                minetest.set_node({x=pos.x + 6, y=pos.y + 2, z=pos.z + 2}, {name="default:wood"})

                return true, fmt:format(args, pos.x, pos.y, pos.z)

            end
        else
            return false, "No vehicle added"
        end

        return false, "No vehicle added"
    end
})
