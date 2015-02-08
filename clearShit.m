out = instrfindall
delete(out)

parallel.defaultClusterProfile('local')
c = parcluster()
out = findobj(c)
out.Jobs
delete(out.Jobs)