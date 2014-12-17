-- Wire Collision Controller by PTugaSantos
-- wire_collision_controller.lua

TOOL.Category		= 'Physics'
TOOL.Name			= '#Collision Controller'
TOOL.Command		= nil
TOOL.ConfigName		= ''
TOOL.Tab			= 'Wire'

cleanup.Register( 'gmod_wire_collision_controller' ) -- Cleanup support

if CLIENT then

	TOOL.ClientConVar[ 'model' ] = 'models/beer/wiremod/hydraulic_mini.mdl'

	language.Add( 'tool.wire_collision_controller.name', 'Collision Controller' )
    language.Add( 'tool.wire_collision_controller.desc', 'Enables the custom collision check' )
    language.Add( 'tool.wire_collision_controller.0', 'Primary: Create Collision Controller | Secundary: Link entity' )
	language.Add( 'tool.wire_collision_controller.1', 'Select entity now' )
	language.Add( 'Cleanup_gmod_wire_collision_controller', 'Clean up Collision Controllers' )
	language.Add( 'Undone_gmod_wire_collision_controller', 'Undone Collision Controller' )
	language.Add( 'Cleaned_gmod_wire_collision_controller', 'Cleaned up all Collision Controllers' )
	language.Add( 'Undone_gmod_wire_collision_controller_link', 'Undone Collision Controller link' )

	net.Receive( 'collide_group_notification', function()
	
		local tbl = net.ReadTable()
		
		GAMEMODE:AddNotify( tbl.msg, tbl.type, 5 )
		
	end	)
	
	function TOOL.BuildCPanel( CPanel )
	
		CPanel:AddControl( 'Header', { Text = '#tool.wire_collision_controller.name', Description = '#tool.wire_collision_controller.desc' }  )

	end

end

if SERVER then

	util.AddNetworkString( 'collide_group_notification' )
	
	function TOOL:notify( msg, type )
		
		local tbl = {}
			tbl.msg = msg
			tbl.type = type
		
		net.Start( 'collide_group_notification' )
		
			net.WriteTable( tbl )
			
		net.Send( self:GetOwner() )
	
	end
	
end

function TOOL:createundo( ent )

	undo.Create( 'gmod_wire_collision_controller' )
		
		undo.AddEntity( ent )
		undo.SetPlayer( self:GetOwner() )

	undo.Finish()

end

function TOOL:LeftClick( tr )
	
	if CLIENT then return true end
	
	if ( tr.Entity:GetClass() == 'gmod_wire_collision_controller' ) then return true end
	
	local ply = self:GetOwner()
	
	local model = self:GetClientInfo( 'model' )
	local ent = tr.Entity
	local pos = tr.HitPos
	local ang = tr.HitNormal:Angle()
		ang.pitch = ( ( ang.pitch + 90 ) / 90 ) * 90
		ang.yaw = math.Round( ang.yaw / 90 ) * 90
		ang.roll = math.Round( ang.roll / 90 ) * 90

	local controller = CollisionController.Create( ply, pos, ang, model )
	
	if ent and not ent:IsWorld() and not ent:IsPlayer() then
	
		constraint.Weld( controller, ent, 0, 0, 0, true, false )
	
	end
	
	self:createundo( controller )

	return true
	
end

function TOOL:RightClick( tr )
	
	if CLIENT then return true end
	
	local ent = tr.Entity

	local key_sh = self:GetOwner():KeyDown( IN_SPEED )
	
	if not ent and not ent:IsWorld() or ent:IsPlayer() then return false end
	
	if ( self:GetStage() == 0 ) and ( ent:GetClass() == 'gmod_wire_collision_controller' ) and not key_sh then
		
		self.controller = ent
		
		self:SetStage( 1 )
		
		return true
		
	end
	
	if ( self:GetStage() == 1 ) and not ( ent:GetClass() == 'gmod_wire_collision_controller' ) and not ent:IsWorld() and not ent:IsPlayer() and not ent:IsNPC() then
		
		local controller = self.controller
		
		if not CollisionController.GetController( ent ) then
		
			controller:Link( ent )
			
			self:notify( 'Linked successfully!', 0 )

			self:SetStage( Either( key_sh, 1, 0 ) )

		else
			
			if ( CollisionController.GetController( ent ) == controller ) then
			
				controller:Unlink( ent )
				
				self:notify( 'Unlinked successfully!', 0 )
				
			else
			
				self:notify( 'That entity already have a collision controller!', 1 )
				
			end
			
		end

		return true
		
	end
	
end

function TOOL:DrawHUD()

	if SERVER then return end
	
	local ent = LocalPlayer():GetEyeTrace().Entity

	if not ( ent:GetClass() == 'gmod_wire_collision_controller' ) then
	
		ent = CollisionController.GetController( ent )
	
	end
	
	if ent and ( ent:GetClass() == 'gmod_wire_collision_controller' ) then
	
		if ent.marks then
		
			for _, v in pairs( ent.marks ) do
				
				if not v or not v:IsValid() then continue end
				if ( ent:GetPos():Distance( v:GetPos() ) > 1000 ) then continue end
				
				local ctrl_pos = ent:GetPos():ToScreen()
				local ent_pos = v:GetPos():ToScreen()
				
				surface.SetDrawColor( 255, 255, 0, 255 )
				surface.DrawLine( ctrl_pos.x, ctrl_pos.y, ent_pos.x, ent_pos.y )
			
			end
			
			halo.Add( ent.marks, Color( 255, 255, 0, 150 ), 2, 2, 2 )
			
		end
	
	end

end

function TOOL:Reload( tr )
	
end

function TOOL:Think()

	if CLIENT then return end
	
	if ( self:GetStage() == 1 ) and self:GetOwner():KeyReleased( IN_SPEED ) then
	
		self:SetStage( 0 )
	
	end

end