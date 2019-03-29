/************************************************************************************
 * Copyright (C) 2016                                                               *
 * TETCOS, Bangalore. India                                                         *
 *                                                                                  *
 * Tetcos owns the intellectual property rights in the Product and its content.     *
 * The copying, redistribution, reselling or publication of any or all of the       *
 * Product or its content without express prior written consent of Tetcos is        *
 * prohibited. Ownership and / or any other right relating to the software and all  *
 * intellectual property rights therein shall remain at all times with Tetcos.      *
 *                                                                                  *
 * Author:    Kanagaraj K                                                           *
 *                                                                                  *
 * ---------------------------------------------------------------------------------*/

 /**********************************IMPORTANT NOTES***********************************
 1. This file contains the Dynamic Clustering code.
 2. For this implementation of Dynamic Clustering, the number of Clusters is set in NUMBEROFCLUSTERS
	varaiable. The user can modify it as per the number of clusters required.
 3. The Network scenario can contain any number of sensors which will be divided into number of
	clusters as specified in the NUMBEROFCLUSTERS variable. The size of each cluster and the
	sensors in each cluster varies dynamically after every CLUSTER_INTERVAL time. This can
	be modified in the DSR.h file.
 4. Mobility can be set to sensors by setting velocity which is zero by default
 ************************************************************************************/


#include "main.h"
#include "DSR.h"
#include "List.h"
#include "../BatteryModel/BatteryModel.h"
#include "../ZigBee/802_15_4.h"
#define NUMBEROFCLUSTERS 4

int *ClusterElements;
int CH[NUMBEROFCLUSTERS];
int CL_SIZE[NUMBEROFCLUSTERS];

int fn_NetSim_dynamic_clustering_CheckDestination(NETSIM_ID nDeviceId, NETSIM_ID nDestinationId)
//Function to check whether the Device ID is same as the Destination ID
{
	if (nDeviceId == nDestinationId)
		return 1;
	else
		return 0;
}

int fn_NetSim_dynamic_clustering_GetNextHop(NetSim_EVENTDETAILS* pstruEventDetails)
//Function to determine the DeviceId of the next hop
{
	int nextHop = 0;
	NETSIM_ID nInterface;


	int i;
	int ClusterId;
	int cl_flag = 0;

	int cls = fn_NetSim_dynamic_clustering_IdentifyCluster(pstruEventDetails->nDeviceId);

	//Static Routes defined for 4 Clusters.
	//If the sensor is the Cluster Head, it forwards it to the Sink.
	//Otherwise, it forwards the packet to the Cluster Head of its cluster.

	if (pstruEventDetails->pPacket->nSourceId == pstruEventDetails->nDeviceId)
		//For the first hop
	{

		if (pstruEventDetails->nDeviceId == CH[cls])
			nextHop = get_first_dest_from_packet(pstruEventDetails->pPacket);
		else
		{
			ClusterId = fn_NetSim_dynamic_clustering_IdentifyCluster(pstruEventDetails->nDeviceId);
			nextHop = CH[ClusterId];
		}
	}
	else
	{

		nextHop = get_first_dest_from_packet(pstruEventDetails->pPacket);
	}


	//Updating the Transmitter ID, Receiver ID and NextHopIP in the pstruEventDetails
	free(pstruEventDetails->pPacket->pstruNetworkData->szNextHopIp);
	pstruEventDetails->pPacket->pstruNetworkData->szNextHopIp = dsr_get_dev_ip(nextHop);
	pstruEventDetails->pPacket->nTransmitterId = pstruEventDetails->nDeviceId;
	pstruEventDetails->pPacket->nReceiverId = nextHop;


	return 1;
}

int fn_NetSim_dynamic_clustering_IdentifyCluster(int DeviceId)
//Function to identify the cluster of the sensor.
{
	return (ClusterElements[DeviceId - 1] - 1);
}

int fn_NetSim_dynamic_clustering_run()
{
	fn_netsim_matlab_run(sensor_count, NUMBEROFCLUSTERS);

}

int fn_netsim_dynamic_form_clusters(double* cl_id, double* cl_size)
//sensors are assigned to respective clusters using the cluster id's obtained from MATLAB
{
	int i = 0;
	for (i = 0; i < sensor_count; i++)
	{
		ClusterElements[i] = cl_id[i];
	}


}

int fn_netsim_assign_cluster_heads(double* cl_head)
//Cluster heads are assigned to respective clusters using the data obtained from MATLAB
{
	int i = 0;
	for (i = 0; i < NUMBEROFCLUSTERS; i++)
		CH[i] = cl_head[i];
	return 1;
}

void fn_NetSim_Dynamic_Clustering_Init()
{
	int i = 0, j = 0;
	for (i = 0; i < NETWORK->nDeviceCount - 1; i++)
	{
		if (strcmp(DEVICE(i + 1)->type, "SENSOR"))
			continue;
		sensor_count++;
	}
	
	ClusterElements = (int*)calloc(sensor_count, sizeof*(ClusterElements));
}