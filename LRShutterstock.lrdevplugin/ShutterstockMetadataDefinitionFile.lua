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
			id = 'ShutterstockUrl',
			title = "SS Url",
			readOnly = false,
			dataType = 'url', 
			searchable = true,
			version = 2,
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
			id = 'ShutterstockEditorial',
			title = "SS Editorial",
			readOnly = true,
			dataType = 'enum', 
			searchable = true,
			browsable = true,
			version = 1,
			values = {
				{
					value = 'True',
					title = "True",
				},
				{
					value = 'False',
					title = "False",
				},
			},
		},

		{
			id = 'ShutterstockUploadDate',
			title = "SS UploadDate",
			readOnly = true,
			dataType = 'string', 
			searchable = true,
			browsable = true,
			version = 1,
		},

		{
			id = 'ShutterstockThumbUrl',
			title = "SS Thumb",
			readOnly = true,
			dataType = 'url', 
			searchable = false,
			browsable = false,
			version = 1,
		},

		{
			id = 'ShutterstockThumbUrl480',
			title = "SS Thumb480",
			readOnly = true,
			dataType = 'url', 
			searchable = false,
			browsable = false,
			version = 1,
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

		{
			id = 'CloseUrl',
			title = "SS close Url",
			readOnly = false,
			dataType = 'url', 
			searchable = true,
			version = 2,
		},

	},
	
	schemaversion = 1,

}
