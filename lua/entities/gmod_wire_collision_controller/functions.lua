
if SERVER then

	hook.Add( 'ShouldCollide', 'collide_group', function( ent1, ent2 )

		local controller = CollisionController.GetController( ent1 )

		if controller then

			if ent2:IsPlayer() then return true end
			if ent2:IsWorld() and ( controller.world == 1 ) then return false end

			local marks = controller.marks 
			
			for _, v in pairs( marks ) do
				
				if ( v == ent2 ) then

					return true
				
				end
			
			end
			
			return false

		end

	end )
	
	function ENT:Link( ent )
		
		if ( ent:GetClass() == 'gmod_wire_collision_controller' ) or not gamemode.Call( 'CanTool', self.owner, { Entity = ent }, 'wire_collision_controller' ) then return end
		
		if ent and ent:IsValid() then
		
			local marks = self.marks or {}
			
			if table.HasValue( marks, ent ) then return end
			
			table.insert( marks, ent )
		
			self.marks = marks

			ent:SetCustomCollisionCheck( true )

			self:UpdateNetworkedMarks()
			
			ent:CallOnRemove( 'CollisionController_Unlink', function( ent ) 
				
				local controller = CollisionController.GetController( ent )
				
				if controller then
				
					controller:Unlink( ent )
				
				end
				
			end )
			
		end
		
		self:UpdateOutputs()
	
	end
	
	function ENT:Unlink( ent )
		
		if not self then return end
		
		local marks = self.marks or {}
		
		if table.HasValue( marks, ent ) then

			table.RemoveByValue( marks, ent )

			if ent and ent:IsValid() then
			
				ent:SetCustomCollisionCheck( false )
				
			end
		
		end
		
		self.marks = marks
		
		self:UpdateNetworkedMarks()
		
		self:UpdateOutputs()
		
	end
	
	util.AddNetworkString( 'collision_controller_update_marks' )
	
	function ENT:UpdateNetworkedMarks( )

		timer.Create( self:EntIndex() .. 'updatemarks', 0.1, 1, function()
			
			if self and self:IsValid() and self.marks then
			
				net.Start( 'collision_controller_update_marks' )
				
					net.WriteEntity( self )
					net.WriteTable( self.marks )
					
				net.Broadcast()
			
			end

		end )
		
	end
	
end

if CLIENT then

	net.Receive( 'collision_controller_update_marks', function()

		local controller = net.ReadEntity()
		local marks = net.ReadTable()
		
		controller.marks = ( marks or {} )

	end )
	
end

function CollisionController.GetController( ent )

	if not ent then return nil end
	
	local controllers = ents.FindByClass( 'gmod_wire_collision_controller' )

	for _, controller in pairs( controllers ) do
		
		local marks = controller.marks or {}
			
		if table.HasValue( marks, ent ) then return controller end
		
	end
	
	return nil
		
end
