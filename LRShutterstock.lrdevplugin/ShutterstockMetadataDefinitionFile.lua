--[[----------------------------------------------------------------------------

Info.lua
ShutterstockMetadataDefinitionFile.lrplugin

--------------------------------------------------------------------------------

 Copyright 2018 Chris Anderson
 All Rights Reserved.

------------------------------------------------------------------------------]]

return {

	metadataFieldsForPhotos = {

		{
			id = 'ShutterstockId',
			title = "SS ID",
			readOnly = false,
			dataType = 'string', 
			searchable = true,
			version = 1,
		},

		{
			id = 'ShutterstockCategory',
			title = "SS Category",
			dataType = 'enum',
			searchable = true,
			browsable = true,
			version = 1,
			values = {
				{
					value = 'Nature',
					title = "Nature",
				},
				{
					value = 'People',
					title = "People",
				},
			},
		},

		{
			id = 'ShutterstockStatus',
			title = "SS Status",
			readOnly = false,
			dataType = 'enum',
			searchable = true,
			browsable = true,
			version = 1,
			values = {
				{
					value = 'Submitted',
					title = "Submitted",
				},
				{
					value = 'Rejected',
					title = "Rejected",
				},
				{
					value = 'Accepted',
					title = "Accepted",
				},
				{
					value = 'Error',
					title = "Error",
				},
			},
		},

		{
			id = 'ShutterstockLast',
			title = "SS Last",
			readOnly = true,
			dataType = 'string', 
			searchable = true,
			browsable = true,
			version = 1,
		},

		{
			id = 'ShutterstockAudit',
			title = "SS Audit",
			readOnly = true,
			dataType = 'string', 
			searchable = true,
			browsable = true,
			version = 1,
		},
	},
	
	schemaversion = 1,

}
