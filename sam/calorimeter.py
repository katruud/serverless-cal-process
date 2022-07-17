import numpy, os, uuid
import pandas as pd
from scipy import stats

# Calorimeter functions
def cal_process(csv_file, volume = 0, deriv_size = 8, participant = 'na'):
	# Formate dataframe
	calrq = pd.read_csv(csv_file, skiprows=[0,2])
	calrq.Time = pd.to_datetime(calrq.Time)

	# MFC Select
	# Sort MFCs by value
	mfclist = calrq.filter(regex='MFCFlow*').sum(axis=0).sort_values(ascending=0)
	# Assume N2 is max and CO2 is second
	n2 = mfclist.index[0]
	co2 = mfclist.index[1]

	# Remove potential trailing number from InflowRate
	calrq['InflowRate'] = calrq.filter(regex='InflowRate*')

	# Calculate derivitive size
	# dt in minutes
	dt_min = (calrq.Time[2]-calrq.Time[1]).total_seconds()/60
	deriv_size = round(deriv_size/(dt_min*2))
	length = len(calrq.Time)

	# derivatives
	# init
	calrq['dO2'],calrq['dCO2'],calrq['dN2'] = (numpy.zeros(length) for i in range(3))
	calrq['dO2'] = lin_deriv(length, deriv_size, calrq['OutflowO2'], dt_min)
	calrq['dCO2'] = lin_deriv(length, deriv_size, calrq['OutflowCO2'], dt_min)
	calrq['dN2'] = -calrq['dO2'] - calrq['dCO2']

	# N2
	calrq['OutflowN2'] = 100 - calrq.OutflowO2 - calrq.OutflowCO2
	calrq['InflowN2'] = 100 - calrq.InflowO2 - calrq.InflowCO2

	# For now, assume push
	# To do: add alternative methods
	cal_push(volume, calrq, n2, co2)

	# Create processed file
	# Add uuid for database
	calrq['uuid'] = [str(uuid.uuid4()) for _ in range(len(calrq.index))]
	calrq['participant'] = participant 
	
	csv_file = os.path.splitext(csv_file)
	result_file = csv_file[0] + '-processed' + csv_file[1]
	calrq.to_csv(result_file,columns=['Time','VO2','VCO2','RQ','InflowO2','InflowCO2','OutflowO2',
	'OutflowCO2','dO2','dCO2','InflowRate','OutflowRate','HaldaneInflow',co2,n2,'participant'])
	resultdf = calrq[['Time','VO2','VCO2','RQ','InflowO2','InflowCO2','OutflowO2',
	'OutflowCO2','dO2','dCO2','InflowRate','OutflowRate','HaldaneInflow',co2,n2,'participant','uuid']]
	
	# Rename Time to avoid conflicts with DDB protected keywords
	resultdf.rename(columns={'Time':'StudyTime'})

	return [resultdf, result_file]

def cal_push(volume, calrq, n2, co2):
	# Metabolic equations
	# Push conversion
	calrq['OutflowRate'] = calrq.InflowRate + calrq.eval(n2) + calrq.eval(co2)
	calrq['HaldaneInflow'] = (calrq.OutflowRate * calrq.OutflowN2 + calrq.dN2 * volume) / calrq.InflowN2
	# Equations
	calrq.VO2 = ( calrq.HaldaneInflow * calrq.InflowO2 - calrq.OutflowRate * calrq.OutflowO2 - calrq.dO2 * volume ) * 10
	calrq.VCO2 = -( (calrq.HaldaneInflow * calrq.InflowCO2 - calrq.OutflowRate * calrq.OutflowCO2) - calrq.dCO2 * volume) * 10
	calrq.RQ = calrq.VCO2 / calrq.VO2
	return calrq

def lin_deriv(length, deriv_size, data, dt_min):
	# linregress derivative method (expensive)
	for i in range(length):
		if i < deriv_size or i > length - deriv_size - 1:
			data.at[i] = 0
		else:
			data.at[i] = stats.linregress(numpy.arange(1,deriv_size*2+1)*dt_min, 
			data[round(i-deriv_size):round(i+deriv_size)])[0]
	return data