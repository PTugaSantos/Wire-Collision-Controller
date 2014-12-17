
CollisionController = CollisionController or {}

include( 'gmod_wire_collision_controller/functions.lua' )

DEFINE_BASECLASS( 'base_wire_entity' )

ENT.Author			= 'PTugaSantos'
ENT.PrintName 		= 'Wire Collision Controller'
ENT.WireDebugName 	= 'Collision Controller'
ENT.Type 			= 'anim'

if CLIENT then 
	
	function ENT:Draw()

		self:DrawModel()

	end
	
	language.Add( 'SBoxLimit_wire_collision_controller', "You've hit the Wire Collision Controller limit!" )
	
	return
	
end

if SERVER then
	
	AddCSLuaFile()
	AddCSLuaFile( 'gmod_wire_collision_controller/functions.lua' )
	
	CreateConVar( 'sbox_maxwire_collision_controller', 5, { FCVAR_SERVER_CAN_EXECUTE, FCVAR_REPLICATED }, 'Max of Wire Collision Controllers' )
	
	function ENT:Initialize()

		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )

		self.marks = {}

		self.Inputs = WireLib.CreateInputs( self, { 'Add_Entity [ENTITY]' } )
		self.Outputs = WireLib.CreateOutputs( self, { 'Entities [ARRAY]' } )
		
		self:SetOverlayText( 'Collision Controller' ) // Doesn't want to work, for some reason...

	end
	
	function ENT:TriggerInput( name, value )
	
		if ( name == 'Add_Entity' ) then
		
			if value or not value:IsValid() then return end
			
			self:Link( value )
			
		end
	
	end
	
	function ENT:UpdateOutputs()
	
		WireLib.TriggerOutput( self, 'Entities', ( self.marks or {} ) )

	end
	
	function CollisionController.Create( ply, pos, ang, model )

		if not ply:CheckLimit( 'wire_collision_controller' ) then return false end
		
		local ent = ents.Create( 'gmod_wire_collision_controller' )
	
			ent:SetModel( model )
			ent:SetPos( pos )
			ent:SetAngles( ang )
			ent:SetCollisionGroup( COLLISION_GROUP_WORLD )
			
		ent:Spawn()

		if CPPI then
	
			ent:CPPISetOwner( ply )

		end
		
		ent.owner = ply
		
		cleanup.Add( ply, 'gmod_wire_collision_controller', ent )
		
		ply:AddCount( 'wire_collision_controller', ent )
		
		return ent
	
	end
	
	duplicator.RegisterEntityClass( 'gmod_wire_collision_controller', CollisionController.Create, 'Pos', 'Ang', 'Model' )
	
	function ENT:OnRemove()
	
		local marks = self.marks or {}
		
		for _, v in pairs( marks ) do
			
			if v and v:IsValid() then
			
				v:SetCustomCollisionCheck( false )
				
			end
		
		end
	
	end
	
	function ENT:BuildDupeInfo()

		local data = self.BaseClass.BuildDupeInfo( self ) or {}

		local marks = {}

		if self.marks then

			for _, v in pairs( self.marks ) do
			
				if v and v:IsValid() then
				
					table.insert( marks, v:EntIndex() )
				
				end
			
			end
		
		end
		
		data.marks = marks
		
		return data
		
	end

	function ENT:ApplyDupeInfo( ply, ent, data, GetEntByID )

		self.BaseClass.ApplyDupeInfo( self, ply, ent, data, GetEntByID )
		
		if data.marks then
		
			for _, v in pairs( data.marks ) do
			
				self:Link( GetEntByID( v ) )
			
			end

		end
		
	end

end